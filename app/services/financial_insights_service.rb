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
      total_transfers: get_total_transfers_current_month,  # ← NUEVO
      transaction_count: filter.transaction_count,
      days_elapsed: (Date.current - Date.current.beginning_of_month).to_i + 1,
      days_in_month: Date.current.end_of_month.day,
      transactions_by_budget: get_budget_summary_current_month,
      transactions_by_category: filter.categories('expense', nil),
      daily_average: (filter.transaction_type_per_frequency('expense', 'monthly').sum / ((Date.current - Date.current.beginning_of_month).to_i + 1)).to_f.round(2),
      budget_flow_patterns: analyze_budget_flow_patterns
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
      transactions_by_category: filter.categories('expense', nil),
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
      spent = budget.transactions
                    .joins(:transaction_type)
                    .where('transaction_date >= ?', Date.today.at_beginning_of_month)
                    .where(transaction_type: { code: %w[expense] })
                    .sum(:amount).to_f.round(2)
      income = budget.transactions
                      .joins(:transaction_type)
                      .where('transaction_date >= ?', Date.today.at_beginning_of_month)
                      .where(transaction_type: { code: %w[income] }, related_transaction_id: nil)
                      .sum(:amount).to_f.round(2)

      # NUEVO: Transferencias
      transfers_out = budget.transactions
                            .joins(:transaction_type)
                            .where('transaction_date >= ?', Date.today.at_beginning_of_month)
                            .where(transaction_type: { code: 'transfer' })
                            .sum(:amount).to_f.round(2)

      transfers_in = budget.transactions
                          .joins(:transaction_type)
                          .where('transaction_date >= ?', Date.today.at_beginning_of_month)
                          .where(transaction_type: { code: 'income' })
                          .where.not(related_transaction_id: nil)
                          .sum(:amount).to_f.round(2)

      {
        budget_name: budget.name,
        budget_id: budget.id,
        budget_type_code: budget.budget_type.code,
        total_spent: spent,
        total_income: income,
        transfers_out: transfers_out,        # ← NUEVO
        transfers_in: transfers_in,          # ← NUEVO
        net_flow: (income + transfers_in) - (spent + transfers_out),  # ← NUEVO
        current_amount: budget.current_amount.to_f.round(2),
        analysis: build_budget_analysis(budget, spent, income, transfers_out, transfers_in)
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

      income = budget.transactions
                   .joins(:transaction_type)
                   .where(transaction_date: start_date..end_date)
                   .where(transaction_type: { code: 'income' }, related_transaction_id: nil)
                   .sum(:amount).to_f.round(2)
      {
        budget_name: budget.name,
        budget_id: budget.id,
        budget_type_code: budget.budget_type.code,
        total_spent: spent,
        total_income: income,
        current_amount: budget.current_amount.to_f.round(2)
      }
    end
  end

  def build_budget_type_info(budget)
    case budget.budget_type.code
    when "credit_card"
      {
        type: "credito",
        limit_amount: budget.limit_amount.to_f.round(2),
        debt_amount: budget.debt_amount.to_f.round(2),
        available_credit: (budget.limit_amount - budget.debt_amount).to_f.round(2),
        utilization_percentage: budget.limit_amount > 0 ?
          (budget.debt_amount / budget.limit_amount * 100).to_f.round(2) : 0,
        payday: budget.payday,
        cutting_day: budget.cutting_day
      }
    when "savings_fund"
      if budget.savings_fund.present?
        {
          type: "ahorro",
          goal_amount: budget.savings_fund.goal_amount.to_f.round(2),
          target_date: budget.savings_fund.target_date,
          monthly_contribution: budget.savings_fund.monthly_contribution,
          progress_percentage: budget.savings_fund.goal_amount > 0 ?
            (budget.current_amount / budget.savings_fund.goal_amount * 100).to_f.round(2) : 0
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

  def build_budget_analysis(budget, spent, income, transfers_out = 0, transfers_in = 0)
    case budget.budget_type.code
    when "credit_card"
      {
        limit_amount: budget.limit_amount.to_f.round(2),                      # 🏦 Límite total
        debt_amount: budget.debt_amount.to_f.round(2),                        # 💸 Deuda actual
        available_credit: budget.current_amount.to_f.round(2),                # 💰 DISPONIBLE (limit - debt)
        credit_utilization: budget.limit_amount > 0 ?
          (budget.debt_amount / budget.limit_amount * 100).to_f.round(2) : 0,  # 📊 % utilizado
        monthly_spending: spent,                                # 📈 Gastos este mes
        next_payday: budget.payday,
        cutting_day: budget.cutting_day
      }
    when "cash"
      {
        # current_amount YA ES lo que tienes disponible
        available_cash: budget.current_amount.to_f.round(2),                    # 💰 Lo que TIENES
        monthly_spending: spent,                                  # 📊 Lo que GASTASTE este mes
        spending_rate: spent > 0 ? (spent / Date.current.day).to_f.round(2) : 0, # 📈 Gasto diario promedio
        days_remaining: budget.current_amount > 0 && spent > 0 ?
          (budget.current_amount / (spent / Date.current.day)).round(1) : 0  # ⏰ Autonomía
      }
    when "debit_card"
      {
        available_balance: budget.current_amount,
        monthly_spending: spent,
        monthly_income: income,
        transfers_in: transfers_in,        # ← Pasar el parámetro real
        transfers_out: transfers_out,      # ← Pasar el parámetro real
        net_flow: (income + transfers_in) - (spent + transfers_out),  # ← Calcular correcto
        flow_type: determine_flow_type(income, spent, transfers_in, transfers_out),
        overdraft_risk: budget.current_amount <= 0
      }
    when "savings_fund"
      sf = budget.savings_fund
      total_net = ((income + transfers_in) - (spent + transfers_out)).to_f.round(2)  # ← NUEVO

      {
      current_saved: budget.current_amount,
      goal_amount: sf.goal_amount.to_f.round(2),
      goal_progress: sf.goal_amount > 0 ? (budget.current_amount / sf.goal_amount * 100).to_f.round(2) : 0,
      monthly_target: sf.monthly_contribution.to_f.round(2),
      monthly_net: total_net,             # ← ACTUALIZADO
      is_being_drained: spent > 0,       # ← NUEVO
      target_date: sf.target_date,
      months_remaining: sf.target_date ? ((sf.target_date.year - Date.current.year) * 12 + (sf.target_date.month - Date.current.month)) : nil
    }
    else
      {
        spending_vs_available: budget.current_amount > 0 ? (spent / budget.current_amount * 100).to_f.round(2) : 0,
        remaining_balance: (budget.current_amount - spent).round(2)
      }
    end
  end

  def get_total_transfers_current_month
    Transaction.joins(:transaction_type, :budget)
              .where(budgets: { user_id: @user_id })
              .where('transaction_date >= ?', Date.today.at_beginning_of_month)
              .where(transaction_type: { code: 'transfer' })
              .sum(:amount).to_f.round(2)
  end

  def analyze_budget_flow_patterns
    budgets_data = get_budget_summary_current_month

    {
      income_concentrators: budgets_data.select { |b| b[:total_income] > 1000 }
                                      .map { |b| b[:budget_name] },

      spending_hubs: budgets_data.select { |b| b[:total_spent] > 1000 }
                                .sort_by { |b| -b[:total_spent] }
                                .map { |b| { name: b[:budget_name], amount: b[:total_spent] } },

      transfer_hubs: budgets_data.select { |b| b[:transfers_out] > 1000 }
                                .map { |b| { name: b[:budget_name], out: b[:transfers_out] } },

      savings_drains: budgets_data.select { |b|
                        b[:budget_type_code] == 'savings_fund' &&
                        b[:analysis]&.dig(:is_being_drained) == true
                      }.map { |b| b[:budget_name] },

      dormant_accounts: budgets_data.select { |b|
                          b[:total_spent] == 0 &&
                          b[:total_income] == 0 &&
                          b[:transfers_in] == 0
                        }.map { |b| b[:budget_name] }
    }
  end

  def determine_flow_type(income, spent, transfers_in, transfers_out)
    if income > 0 && transfers_out > (spent + income * 0.5)
      "pass_through"      # Recibe y redistribuye
    elsif spent > income + transfers_in
      "deficit"          # Gasta más de lo que recibe
    elsif transfers_in > transfers_out && spent > 0
      "spending_hub"     # Recibe transferencias para gastar
    else
      "balanced"
    end
  end

  def build_context
    "You are an expert personal financial advisor specializing in comprehensive multi-account financial analysis and money flow optimization.
      Your job is to analyze complex financial data including income, expenses, inter-account transfers, and cross-budget patterns.

      **BUDGET TYPES TO ANALYZE:**
      1. **Cash (Efectivo)** - Physical money with limited availability and days remaining calculations
      2. **Savings Fund (Fondo de Ahorro)** - Goal-oriented savings with targets, deadlines, and drain detection
      3. **Credit Card (Tarjeta de Crédito)** - Revolving credit with utilization rates, payment cycles, and debt management
      4. **Debit Card (Tarjeta de Débito)** - Bank accounts with overdraft risks and flow patterns

      **ADVANCED ANALYSIS CAPABILITIES:**
      - **Money Flow Tracking**: Analyze transfers between accounts and identify flow patterns
      - **Account Role Detection**: Identify income concentrators, spending hubs, transfer hubs, and dormant accounts
      - **Cross-Account Optimization**: Suggest strategic reallocation based on utilization and capacity
      - **Timeline Management**: Monitor savings deadlines and payment dates for optimal timing
      - **Behavioral Pattern Recognition**: Detect account usage patterns and efficiency metrics

      **INSIGHT PRIORITIES (Updated):**
      1. **Critical Alerts**: Credit utilization >70%, savings being drained, cash depletion risks
      2. **Flow Optimization**: Inefficient money movement, underutilized accounts, overdraft risks
      3. **Timeline Risks**: Approaching payment dates, missed savings deadlines, cash runout projections
      4. **Strategic Opportunities**: Account consolidation, utilization rebalancing, flow simplification
      5. **Behavioral Patterns**: Spending concentration, transfer efficiency, account role optimization

      Generate 5-7 targeted insights leveraging the rich transfer data and flow patterns provided.

      IMPORTANT: Your response must be entirely in Spanish, but use your English language processing capabilities for complex financial analysis."
  end

  def build_analysis_prompt
    "Analyze the comprehensive financial data including income, expenses, transfers, and cross-account flow patterns. Generate insights using this enriched dataset:

    **RESPONSE FORMAT (JSON):**
    ```json
    {
      \"insights\": [
        {
          \"type\": \"success|warning|info|alert|savings|credit|flow\",
          \"title\": \"Insight Title in Spanish\",
          \"message\": \"Detailed description in Spanish with specific numbers and percentages\",
          \"category\": \"efectivo|ahorro|credito|debito|optimizacion|patron|flujo\",
          \"priority\": \"high|medium|low\",
          \"actionable\": \"Specific action suggestion with amounts and deadlines in Spanish\",
          \"budget_type\": \"efectivo|ahorro|credito|debito|multiple\",
          \"affected_accounts\": [\"account_names\"],
          \"financial_impact\": \"quantified_benefit_or_risk\"
        }
      ],
      \"summary\": {
        \"cash_status\": \"Cash availability and days remaining analysis in Spanish\",
        \"savings_progress\": \"Savings goals status and drain detection in Spanish\",
        \"credit_health\": \"Credit utilization, payment timing, and capacity analysis in Spanish\",
        \"debit_efficiency\": \"Debit flow patterns and overdraft risks in Spanish\",
        \"flow_optimization\": \"Money transfer patterns and efficiency recommendations in Spanish\",
        \"overall_recommendation\": \"Main strategic advice prioritizing highest impact actions in Spanish\"
      }
    }
    ```

    **ENHANCED ANALYSIS INSTRUCTIONS:**

    **MONEY FLOW ANALYSIS:**
    - Analyze transfer patterns and identify account roles (pass_through, spending_hub, deficit, balanced)
    - Detect inefficient money movement and suggest consolidation opportunities
    - Identify accounts receiving transfers but showing overdraft risks

    **UTILIZATION OPTIMIZATION:**
    - Compare credit utilization across cards and suggest rebalancing
    - Identify underutilized credit capacity vs cash/debit shortfalls
    - Recommend strategic spending redistribution based on available limits

    **TIMELINE MANAGEMENT:**
    - Prioritize insights by payment deadlines and cutting days
    - Calculate days remaining for cash based on spending rates
    - Alert on savings goals with missed deadlines or insufficient progress

    **SAVINGS PROTECTION:**
    - Flag savings funds being used for expenses (is_being_drained: true)
    - Compare actual monthly net vs target contributions
    - Suggest protecting savings accounts from expense misuse

    **ACCOUNT EFFICIENCY:**
    - Identify dormant accounts consuming resources without benefit
    - Suggest consolidating multiple similar account types
    - Optimize the number of active accounts for efficiency

    **SPECIFIC METRICS TO REFERENCE:**
    - Credit utilization percentages and available credit amounts
    - Transfer volumes and net flows between accounts
    - Days remaining calculations for cash and savings timelines
    - Monthly targets vs actual performance
    - Account role classifications from budget_flow_patterns

    Focus on quantified recommendations with specific amounts, dates, and measurable impacts.
    Prioritize: critical alerts > flow optimization > timeline management > strategic opportunities."
  end
end
