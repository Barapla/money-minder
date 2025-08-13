class FinancialInsightsService
  def initialize(user_id)
    @user_id = user_id
    @claude_service = ClaudeService.new
  end

  def generate_insights
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
        expense_filtering: "Only real expenses included (transaction_type = 'expense')",
        income_filtering: "Only genuine income included (income without related_transaction_id)",
        transfers_excluded: "Account transfers between user's accounts excluded to prevent double counting"
      }
    }

    prompt = build_analysis_prompt

    # Enviar a Claude
    @claude_service.send_message(
      prompt: prompt,
      context: context,
      data: financial_data
    )
  end

  private

  def get_current_month_data
    start_date = Date.current.beginning_of_month
    end_date = Date.current

    transactions = Transaction.joins(:budget)
                             .where(user_id: @user_id, active: true)
                             .where(transaction_date: start_date..end_date)
                             .includes(:budget, :category)

    {
      total_spent: transactions.sum(:amount).to_f.round(2),
      transaction_count: transactions.count,
      days_elapsed: (Date.current - start_date).to_i + 1,
      days_in_month: start_date.end_of_month.day,
      transactions_by_budget: group_transactions_by_budget(transactions),
      transactions_by_category: group_transactions_by_category(transactions),
      daily_average: (transactions.sum(:amount) / ((Date.current - start_date).to_i + 1)).to_f.round(2)
    }
  end

  def get_previous_month_data
    start_date = 1.month.ago.beginning_of_month
    end_date = 1.month.ago.end_of_month

    transactions = Transaction.joins(:budget)
                             .where(user_id: @user_id, active: true)
                             .where(transaction_date: start_date..end_date)
                             .includes(:budget, :category)

    {
      total_spent: transactions.sum(:amount).to_f.round(2),
      transaction_count: transactions.count,
      transactions_by_budget: group_transactions_by_budget(transactions),
      transactions_by_category: group_transactions_by_category(transactions),
      daily_average: (transactions.sum(:amount) / (end_date - start_date).to_i).to_f.round(2)
    }
  end

  def get_active_budgets
    Budget.where(user_id: @user_id, active: true).includes(:credit_card, :savings_fund).map do |budget|
      budget_data = {
        id: budget.id,
        name: budget.name,
        current_amount: budget.current_amount.to_f.round(2),
        budget_type_id: budget.budget_type_id,
        budget_type_name: get_budget_type_name(budget.budget_type.code),
        personal: budget.personal
      }

      # Agregar datos específicos según el tipo de presupuesto
      case budget.budget_type.code
      when "credit_card" # Tarjeta de crédito
        if budget.credit_card.present?
          budget_data[:type_info] = {
            type: "credito",
            limit_amount: budget.credit_card.limit_amount,
            debt_amount: budget.credit_card.debt_amount,
            available_credit: (budget.credit_card.limit_amount - budget.credit_card.debt_amount).to_f.round(2),
            utilization_percentage: budget.credit_card.limit_amount > 0 ?
              (budget.credit_card.debt_amount / budget.credit_card.limit_amount * 100).to_f.round(2) : 0,
            payday: budget.credit_card.payday,
            cutting_day: budget.credit_card.cutting_day
          }
        else
          # Si no hay datos de credit_card, asumir que current_amount es el disponible
          budget_data[:type_info] = {
            type: "credito",
            available_credit: budget.current_amount
          }
        end
      when "cash" # Efectivo
        budget_data[:type_info] = {
          type: "efectivo",
          available_cash: budget.current_amount
        }
      when "debit_card" # Tarjeta de débito
        budget_data[:type_info] = {
          type: "debito",
          available_balance: budget.current_amount
        }
      when "savings_fund" # Fondo de ahorro
        if budget.savings_fund.present?
          budget_data[:type_info] = {
            type: "ahorro",
            goal_amount: budget.savings_fund.goal_amount,
            target_date: budget.savings_fund.target_date,
            monthly_contribution: budget.savings_fund.monthly_contribution,
            progress_percentage: budget.savings_fund.goal_amount > 0 ?
              (budget.current_amount / budget.savings_fund.goal_amount * 100).to_f.round(2) : 0
          }
        end
      else
        budget_data[:type_info] = {
          type: "digital",
          available_balance: budget.current_amount
        }
      end

      budget_data
    end
  end

  def get_budget_type_name(type_code)
    # Mapeo basado en los IDs reales de tu base de datos
    case type_code
    when "credit_card" then "Tarjeta de Crédito"    # AMEX, Nu Credito, Plata, BBVA Crédito
    when "cash" then "Efectivo"              # Efectivo de Bryan
    when "debit_card" then "Tarjeta de Débito"     # Santander Nómina, BBVA Debito, Nu Debito
    when "savings_fund" then "Fondo de Ahorro"       # Para cuando tengas fondos de ahorro
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
      when "credit_card" # Tarjeta de crédito
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
          # Si no hay datos específicos de credit_card, usar current_amount como referencia
          budget_info[:analysis] = {
            available_credit: budget.current_amount,
            monthly_spending: total_spent,
            spending_vs_available: budget.current_amount > 0 ? (total_spent / budget.current_amount * 100).to_f.round(2) : 0
          }
        end
      when "cash" # Efectivo
        budget_info[:analysis] = {
          spending_vs_available: budget.current_amount > 0 ? (total_spent / budget.current_amount * 100).to_f.round(2) : 0,
          remaining_cash: (budget.current_amount - total_spent).to_f.round(2),
          days_remaining: budget.current_amount > 0 && total_spent > 0 ?
            (budget.current_amount / (total_spent / Date.current.day)).round(1) : 0
        }
      when "debit_card" # Tarjeta de débito
        budget_info[:analysis] = {
          spending_vs_budget: budget.current_amount > 0 ? (total_spent / budget.current_amount * 100).to_f.round(2) : 0,
          remaining_budget: (budget.current_amount - total_spent).to_f.round(2),
          overdraft_risk: budget.current_amount == 0 && total_spent > 0
        }
      when "savings_fund" # Fondo de ahorro
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
    # Agrupar solo gastos reales por categoría
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

    **ANALYSIS RULES BY BUDGET TYPE:**

    **CASH (Efectivo):**
    - Alert if spending exceeds available cash
    - Monitor cash flow sustainability
    - Suggest cash management strategies

    **SAVINGS FUND (Ahorro):**
    - Track progress toward goal_amount and target_date
    - Analyze monthly_contribution consistency
    - Alert on timeline risks or missed contributions
    - Calculate required monthly savings to meet goals

    **CREDIT CARD (Crédito):**
    - CRITICAL: Alert if utilization > 70% of limit_amount
    - Monitor debt_amount trends vs previous month
    - Consider payday and cutting_day for payment timing
    - Alert on approaching credit limits

    **DEBIT CARD (Débito):**
    - Compare spending vs current_amount budget
    - Identify overspending patterns
    - Suggest budget reallocation

    **CROSS-ACCOUNT OPTIMIZATION:**
    - Identify unused credit capacity vs cash shortfalls
    - Suggest moving spending between account types
    - Balance risk across different account types
    - Optimize payment timing across cards

    **INSIGHT EXAMPLES (all in Spanish):**
    - Credit: 'Tu tarjeta BBVA tiene 85% de utilización - riesgo alto para tu score crediticio'
    - Savings: 'Vas 23% atrasado en tu meta de ahorro - necesitas $450 extra este mes'
    - Cash: 'Tu efectivo se agotará en 8 días al ritmo actual de gastos'
    - Debit: 'Has usado solo 34% de tu presupuesto de débito - puedes redistribuir fondos'
    - Optimization: 'Tienes $15,000 disponibles en crédito mientras gastas efectivo escaso'

    Focus on account-type-specific risks and cross-account optimization opportunities.
    Prioritize: credit alerts > savings timeline risks > cash flow issues > optimization opportunities."
  end
end
