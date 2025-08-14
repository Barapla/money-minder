class FinancialInsightsService
  def initialize(user_id)
    @user_id = user_id
    @claude_service = ClaudeService.new
  end

  # Método público que guarda el reporte (para llamadas directas)
  def generate_insights
    result = generate_insights_without_saving

    # Solo guardar si fue exitoso y no se está llamando desde AiReportService
    if result[:success] && !Thread.current[:generating_ai_report]
      begin
        Thread.current[:generating_ai_report] = true
        AiReportService.create_financial_general_report(@user_id)
      ensure
        Thread.current[:generating_ai_report] = false
      end
    end

    result
  end

  # Método interno que NO guarda el reporte (evita bucle)
  def generate_insights_without_saving
    # Obtener datos del mes actual y anterior
    current_month_data = get_current_month_data
    previous_month_data = get_previous_month_data
    budgets_data = get_active_budgets

    # Preparar el contexto y datos para Claude
    context = build_context
    financial_data = {
      current_month: current_month_data,
      previous_month: previous_month_data,
      budgets: budgets_data,
      analysis_date: Date.current.strftime("%B %Y"),
      data_notes: {
        expense_filtering: "Only real expenses included",
        income_filtering: "Only genuine income included",
        transfers_excluded: "Account transfers excluded"
      }
    }

    prompt = build_analysis_prompt

    # Enviar a Claude SIN guardar reporte
    @claude_service.send_message(
      prompt: prompt,
      context: context,
      data: financial_data
    )
  end

  private

  def get_current_month_data
    filter = ReportFilter.new(
      start_date: Date.current.beginning_of_month,
      end_date: Date.current
    )

    {
      total_spent: filter.transaction_type_per_frequency('expense', 'monthly').sum.to_f.round(2),
      total_income: filter.transaction_type_per_frequency('income', 'monthly').sum.to_f.round(2),
      transaction_count: filter.transaction_count,
      days_elapsed: (Date.current - Date.current.beginning_of_month).to_i + 1,
      days_in_month: Date.current.end_of_month.day,
      transactions_by_budget: get_budget_summary_current_month,
      transactions_by_category: filter.categories('expense', 10),
      daily_average: (filter.transaction_type_per_frequency('expense', 'monthly').sum / ((Date.current - Date.current.beginning_of_month).to_i + 1)).to_f.round(2)
    }
  end

  def get_previous_month_data
    filter = ReportFilter.new(
      start_date: 1.month.ago.beginning_of_month,
      end_date: 1.month.ago.end_of_month
    )

    days_in_month = (1.month.ago.end_of_month - 1.month.ago.beginning_of_month).to_i + 1

    {
      total_spent: filter.transaction_type_per_frequency('expense', 'monthly').sum.to_f.round(2),
      total_income: filter.transaction_type_per_frequency('income', 'monthly').sum.to_f.round(2),
      transaction_count: filter.transaction_count,
      transactions_by_budget: get_budget_summary_previous_month,
      transactions_by_category: filter.categories('expense', 10),
      daily_average: (filter.transaction_type_per_frequency('expense', 'monthly').sum / days_in_month).to_f.round(2)
    }
  end

  def get_active_budgets
    Budget.where(user_id: @user_id, active: true)
          .includes(:credit_card, :savings_fund, :budget_type)
          .map do |budget|
      {
        id: budget.id,
        name: budget.name,
        current_amount: budget.current_amount.to_f.round(2),
        budget_type_code: budget.budget_type.code,
        budget_type_name: budget.budget_type.value,
        personal: budget.personal,
        type_info: build_budget_type_info(budget)
      }
    end
  end

  def get_budget_summary_current_month
    Budget.where(user_id: @user_id, active: true).map do |budget|
      spent = budget.spent_amount_this_month.to_f.round(2)

      {
        budget_name: budget.name,
        budget_id: budget.id,
        budget_type_code: budget.budget_type.code,
        total_spent: spent,
        current_amount: budget.current_amount.to_f.round(2),
        analysis: build_budget_analysis(budget, spent)
      }
    end
  end

  def get_budget_summary_previous_month
    start_date = 1.month.ago.beginning_of_month
    end_date = 1.month.ago.end_of_month

    Budget.where(user_id: @user_id, active: true).map do |budget|
      spent = budget.transactions
                  .joins(:transaction_type)
                  .where(transaction_date: start_date..end_date)
                  .where(transaction_type: { code: 'expense' })
                  .sum(:amount).to_f.round(2)

      {
        budget_name: budget.name,
        budget_id: budget.id,
        budget_type_code: budget.budget_type.code,
        total_spent: spent,
        current_amount: budget.current_amount.to_f.round(2)
      }
    end
  end

  def build_budget_type_info(budget)
    case budget.budget_type.code
    when "credit_card"
      {
        type: "credito",
        limit_amount: budget.limit_amount,
        debt_amount: budget.debt_amount,
        available_credit: (budget.limit_amount - budget.debt_amount).to_f.round(2),
        utilization_percentage: budget.limit_amount > 0 ?
          (budget.debt_amount / budget.limit_amount * 100).round(2) : 0,
        payday: budget.payday,
        cutting_day: budget.cutting_day
      }
    when "savings_fund"
      if budget.savings_fund.present?
        {
          type: "ahorro",
          goal_amount: budget.savings_fund.goal_amount,
          target_date: budget.savings_fund.target_date,
          monthly_contribution: budget.savings_fund.monthly_contribution,
          progress_percentage: budget.savings_fund.goal_amount > 0 ?
            (budget.current_amount / budget.savings_fund.goal_amount * 100).round(2) : 0
        }
      end
    when "cash"
      { type: "efectivo", available_cash: budget.current_amount }
    when "debit_card"
      { type: "debito", available_balance: budget.current_amount }
    else
      { type: "digital", available_balance: budget.current_amount }
    end
  end

  def build_budget_analysis(budget, spent)
    case budget.budget_type.code
    when "credit_card"
      {
        credit_utilization: budget.limit_amount > 0 ? (budget.debt_amount / budget.limit_amount * 100).round(2) : 0,
        available_credit: budget.limit_amount - budget.debt_amount,
        monthly_spending: spent,
        next_payday: budget.payday,
        cutting_day: budget.cutting_day
      }
    when "cash"
      days_remaining = budget.current_amount > 0 && spent > 0 ?
        (budget.current_amount / budget.average_daily_spent).round(1) : 0

      {
        spending_vs_available: budget.current_amount > 0 ? (spent / budget.current_amount * 100).round(2) : 0,
        remaining_cash: (budget.current_amount - spent).round(2),
        days_remaining: days_remaining
      }
    when "debit_card"
      {
        spending_vs_budget: budget.current_amount > 0 ? (spent / budget.current_amount * 100).round(2) : 0,
        remaining_budget: (budget.current_amount - spent).round(2),
        overdraft_risk: budget.current_amount == 0 && spent > 0
      }
    when "savings_fund"
      if budget.savings_fund.present?
        sf = budget.savings_fund
        {
          goal_progress: sf.goal_amount > 0 ? (budget.current_amount / sf.goal_amount * 100).round(2) : 0,
          monthly_target: sf.monthly_contribution.to_f.round(2),
          target_date: sf.target_date,
          days_to_goal: sf.target_date ? (sf.target_date - Date.current).to_i : nil
        }
      end
    else
      {
        spending_vs_available: budget.current_amount > 0 ? (spent / budget.current_amount * 100).round(2) : 0,
        remaining_balance: (budget.current_amount - spent).round(2)
      }
    end
  end

  def get_budget_type_name(type_code)
    case type_code
    when "credit_card" then "Tarjeta de Crédito"
    when "cash" then "Efectivo"
    when "debit_card" then "Tarjeta de Débito"
    when "savings_fund" then "Fondo de Ahorro"
    else "Desconocido (Codigo: #{type_code})"
    end
  end

  def group_transactions_by_budget(transactions)
    transactions.group_by(&:budget).map do |budget, trans|
      total_spent = trans.sum(&:amount).to_f.round(2)

      budget_info = {
        budget_name: budget.name,
        budget_id: budget.id,
        budget_type_id: budget.budget_type_id,
        budget_type_name: get_budget_type_name(budget.budget_type.code),
        total_spent: total_spent,
        transaction_count: trans.count,
        current_amount: budget.current_amount.to_f.round(2)
      }

      # Análisis específico según tipo de presupuesto
      case budget.budget_type.code
      when "credit_card"
        if budget.credit_card.present?
          cc = budget.credit_card
          budget_info[:analysis] = {
            credit_utilization: cc.limit_amount > 0 ? (cc.debt_amount / cc.limit_amount * 100).to_f.round(2) : 0,
            available_credit: cc.limit_amount - cc.debt_amount,
            monthly_spending: total_spent,
            next_payday: cc.payday,
            cutting_day: cc.cutting_day
          }
        else
          budget_info[:analysis] = {
            available_credit: budget.current_amount,
            monthly_spending: total_spent,
            spending_vs_available: budget.current_amount > 0 ? (total_spent / budget.current_amount * 100).to_f.round(2) : 0
          }
        end
      when "cash"
        budget_info[:analysis] = {
          spending_vs_available: budget.current_amount > 0 ? (total_spent / budget.current_amount * 100).to_f.round(2) : 0,
          remaining_cash: (budget.current_amount - total_spent).to_f.round(2),
          days_remaining: budget.current_amount > 0 && total_spent > 0 ?
            (budget.current_amount / (total_spent / Date.current.day)).round(1) : 0
        }
      when "debit_card"
        budget_info[:analysis] = {
          spending_vs_budget: budget.current_amount > 0 ? (total_spent / budget.current_amount * 100).to_f.round(2) : 0,
          remaining_budget: (budget.current_amount - total_spent).to_f.round(2),
          overdraft_risk: budget.current_amount == 0 && total_spent > 0
        }
      when "savings_fund"
        if budget.savings_fund.present?
          sf = budget.savings_fund
          budget_info[:analysis] = {
            goal_progress: sf.goal_amount > 0 ? (budget.current_amount / sf.goal_amount * 100).to_f.round(2) : 0,
            monthly_target: sf.monthly_contribution.to_f.round(2),
            target_date: sf.target_date,
            days_to_goal: sf.target_date ? (sf.target_date - Date.current).to_i : nil
          }
        end
      else
        budget_info[:analysis] = {
          spending_vs_available: budget.current_amount > 0 ? (total_spent / budget.current_amount * 100).to_f.round(2) : 0,
          remaining_balance: budget.current_amount - total_spent,
          utilization_rate: budget.current_amount > 0 ? (total_spent / budget.current_amount * 100).to_f.round(2) : 0
        }
      end

      budget_info
    end
  end

  def group_transactions_by_category(transactions)
    transactions.joins(:category)
                .group('categories.name')
                .sum(:amount)
                .map do |category_name, total|
      {
        category: category_name,
        total: total.to_f.round(2),
        count: transactions.joins(:category)
                          .where(categories: { name: category_name })
                          .count
      }
    end
  end

  def build_context
    "You are an expert personal financial advisor specializing in comprehensive financial analysis across different account types.
    Your job is to analyze user financial data considering 4 distinct budget types with different behaviors and rules:

    **BUDGET TYPES TO ANALYZE:**
    1. **Cash (Efectivo)** - Physical money, limited by available amount
    2. **Savings Fund (Fondo de Ahorro)** - Goal-oriented savings with targets and contributions
    3. **Credit Card (Tarjeta de Crédito)** - Revolving credit with limits, debt, and payment cycles
    4. **Debit Card (Tarjeta de Débito)** - Bank account spending within available balance

    **ANALYSIS FOCUS BY TYPE:**
    - **Cash**: Monitor spending vs available cash, cash flow management
    - **Savings**: Progress toward goals, contribution consistency, timeline adherence
    - **Credit**: Utilization rates, debt management, payment timing, available credit
    - **Debit**: Budget adherence, balance management, spending patterns

    **INSIGHT PRIORITIES:**
    1. **Credit Card Alerts**: High utilization (>70%), debt accumulation, payment dates
    2. **Savings Progress**: Goal achievement status, contribution gaps, timeline risks
    3. **Cash Flow Issues**: Insufficient cash, overspending vs available funds
    4. **Budget Optimization**: Rebalancing across account types, unused capacity
    5. **Spending Patterns**: Cross-account behavior, seasonal trends

    Generate 4-6 targeted insights prioritizing account-specific concerns and cross-account optimization opportunities.

    IMPORTANT: Your response must be entirely in Spanish, but use your English language processing capabilities for complex financial analysis."
  end

  def build_analysis_prompt
    "Analyze the provided financial data considering the 4 distinct budget types and their specific characteristics. Generate targeted insights following these criteria:

    **RESPONSE FORMAT (JSON):**
    ```json
    {
      \"insights\": [
        {
          \"type\": \"success|warning|info|alert|savings|credit\",
          \"title\": \"Insight Title in Spanish\",
          \"message\": \"Detailed description in Spanish\",
          \"category\": \"efectivo|ahorro|credito|debito|optimizacion|patron\",
          \"priority\": \"high|medium|low\",
          \"actionable\": \"Specific action suggestion in Spanish\",
          \"budget_type\": \"efectivo|ahorro|credito|debito|multiple\"
        }
      ],
      \"summary\": {
        \"cash_status\": \"Cash flow analysis in Spanish\",
        \"savings_progress\": \"Savings goals status in Spanish\",
        \"credit_health\": \"Credit utilization and debt status in Spanish\",
        \"debit_efficiency\": \"Debit card budget performance in Spanish\",
        \"overall_recommendation\": \"Main strategic advice in Spanish\"
      }
    }
    ```

    Focus on account-type-specific risks and cross-account optimization opportunities.
    Prioritize: credit alerts > savings timeline risks > cash flow issues > optimization opportunities."
  end
end
