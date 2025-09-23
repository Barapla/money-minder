# frozen_string_literal: true

# Service para generar insights financieros usando Claude
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

    financial_data = {
      current_month: current_month_data,
      previous_month: previous_month_data,
      budgets: budgets_data,
      analysis_date: Date.current.strftime('%B %Y'),
      data_notes: {
        expense_filtering: 'Only real expenses included',
        income_filtering: 'Only genuine income included',
        transfers_excluded: 'Account transfers excluded'
      }
    }

    # Preparar el contexto y datos para Claude
    context = build_context
    prompt = build_analysis_prompt

    # Enviar a Claude SIN guardar reporte
    result = @claude_service.send_message(prompt:, context:, data: financial_data)

    if result[:success] && result[:parsed_json]
      {
        success: true,
        insights: result[:parsed_json],
        format: 'json'
      }
    elsif result[:success]
      # Fallback: devolver como texto pero loggear el problema
      Rails.logger.warn 'JSON parsing failed, returning raw content'
      {
        success: true,
        insights: result[:content],
        format: 'text',
        parsing_error: true
      }
    else
      { success: false, error: result[:error] }
    end
  end

  def get_prompt_example
    # Obtener datos del mes actual y anterior
    current_month_data = get_current_month_data
    # previous_month_data = get_previous_month_data
    # budgets_data = get_active_budgets

    financial_data = {
      current_month: current_month_data,
      # previous_month: previous_month_data,
      # budgets: budgets_data,
      analysis_date: Date.current.strftime('%B %Y'),
      data_notes: {
        expense_filtering: 'Only real expenses included',
        income_filtering: 'Only genuine income included',
        transfers_excluded: 'Account transfers excluded'
      }
    }

    # Preparar el contexto y datos para Claude
    context = build_context
    prompt = build_analysis_prompt

    { context:, prompt:, financial_data: }
  end

  private

  def get_transactions_for_cycle(cycle)
    cycle.transactions.order(transaction_date: :desc)
  end

  def get_current_month_data
    filter = ReportFilter.new(
      start_date: Date.current.beginning_of_month,
      end_date: Date.current
    )

    {
      total_spent: filter.transaction_type_per_frequency('expense', 'monthly').sum.to_f.round(2),
      total_income: filter.transaction_type_per_frequency('income', 'monthly').sum.to_f.round(2),
      total_transfers: get_total_transfers_current_month, # ← NUEVO
      transaction_count: filter.transaction_count,
      days_elapsed: (Date.current - Date.current.beginning_of_month).to_i + 1,
      days_in_month: Date.current.end_of_month.day,
      transactions_by_budget: get_budget_summary_current_month,
      transactions_by_category: filter.categories('expense', nil),
      daily_average: (filter.transaction_type_per_frequency('expense',
                                                            'monthly').sum / ((Date.current - Date.current.beginning_of_month).to_i + 1)).to_f.round(2),
      budget_flow_patterns: analyze_budget_flow_patterns,
      available_funds_for_credit: calculate_available_funds_for_credit_optimization,
      optimal_payments: calculate_optimal_payments,
      credit_utilization_summary: calculate_total_utilization_summary
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
        transfers_out:, # ← NUEVO
        transfers_in:, # ← NUEVO
        net_flow: (income + transfers_in) - (spent + transfers_out), # ← NUEVO
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
    when 'credit_card'
      {
        type: 'credito',
        limit_amount: budget.limit_amount.to_f.round(2),
        debt_amount: budget.debt_amount.to_f.round(2),
        available_credit: (budget.limit_amount - budget.debt_amount).to_f.round(2),
        utilization_percentage: if budget.limit_amount.positive?
                                  (budget.debt_amount / budget.limit_amount * 100).to_f.round(2)
                                else
                                  0
                                end,
        payday: budget.payday,
        cutting_day: budget.cutting_day
      }
    when 'savings_fund'
      if budget.savings_fund.present?
        {
          type: 'ahorro',
          goal_amount: budget.savings_fund.goal_amount.to_f.round(2),
          target_date: budget.savings_fund.target_date,
          monthly_contribution: budget.savings_fund.monthly_contribution.to_f.round(2),
          progress_percentage: if budget.savings_fund.goal_amount.positive?
                                 (budget.current_amount / budget.savings_fund.goal_amount * 100).to_f.round(2)
                               else
                                 0
                               end
        }
      end
    when 'cash'
      { type: 'efectivo', available_cash: budget.current_amount.to_f.round(2) }
    when 'debit_card'
      { type: 'debito', available_balance: budget.current_amount.to_f.round(2) }
    else
      { type: 'digital', available_balance: budget.current_amount.to_f.round(2) }
    end
  end

  def build_budget_analysis(budget, spent, income, transfers_out = 0, transfers_in = 0)
    case budget.budget_type.code
    when 'credit_card'
      cycle_info = get_current_cycle_info(budget)

      {
        limit_amount: budget.limit_amount.to_f.round(2),                      # 🏦 Límite total
        debt_amount: budget.debt_amount.to_f.round(2),                        # 💸 Deuda actual
        available_credit: budget.current_amount.to_f.round(2),                # 💰 DISPONIBLE (limit - debt)
        credit_utilization: if budget.limit_amount.positive?
                              (budget.debt_amount / budget.limit_amount * 100).to_f.round(2)
                            else
                              0
                            end, # 📊 % utilizado
        monthly_spending: spent, # 📈 Gastos este mes
        next_payday: budget.payday,
        cutting_day: budget.cutting_day,
        cycle_info:,
        optimal_payment: cycle_info ? calculate_optimal_payment_for_card(budget, cycle_info) : nil
      }
    when 'cash'
      {
        # current_amount YA ES lo que tienes disponible
        available_cash: budget.current_amount.to_f.round(2), # 💰 Lo que TIENES
        monthly_spending: spent, # 📊 Lo que GASTASTE este mes
        spending_rate: spent.positive? ? (spent / Date.current.day).to_f.round(2) : 0, # 📈 Gasto diario promedio
        days_remaining: if budget.current_amount.positive? && spent.positive?
                          (budget.current_amount / (spent / Date.current.day)).to_i.round(1)
                        else
                          0
                        end
      }
    when 'debit_card'
      {
        available_balance: budget.current_amount.to_f.round(2), # 💰 Lo que TIENES
        monthly_spending: spent,
        monthly_income: income,
        transfers_in:, # ← Pasar el parámetro real
        transfers_out:, # ← Pasar el parámetro real
        net_flow: (income + transfers_in) - (spent + transfers_out), # ← Calcular correcto
        flow_type: determine_flow_type(income, spent, transfers_in, transfers_out),
        overdraft_risk: budget.current_amount <= 0
      }
    when 'savings_fund'
      sf = budget.savings_fund
      total_net = ((income + transfers_in) - (spent + transfers_out)).to_f.round(2) # ← NUEVO

      {
        current_saved: budget.current_amount.to_f.round(2),
        goal_amount: sf.goal_amount.to_f.round(2),
        goal_progress: sf.goal_amount.positive? ? (budget.current_amount / sf.goal_amount * 100).to_f.round(2) : 0,
        monthly_target: sf.monthly_contribution.to_f.round(2),
        monthly_net: total_net, # ← ACTUALIZADO
        is_being_drained: spent.positive?, # ← NUEVO
        target_date: sf.target_date,
        months_remaining: sf.target_date ? ((sf.target_date.year - Date.current.year) * 12 + (sf.target_date.month - Date.current.month)) : nil
      }
    else
      {
        spending_vs_available: budget.current_amount.positive? ? (spent / budget.current_amount * 100).to_f.round(2) : 0,
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

      savings_drains: budgets_data.select do |b|
                        b[:budget_type_code] == 'savings_fund' &&
                          b[:analysis]&.dig(:is_being_drained) == true
                      end.map { |b| b[:budget_name] },

      dormant_accounts: budgets_data.select do |b|
                          (b[:total_spent]).zero? &&
                            (b[:total_income]).zero? &&
                            (b[:transfers_in]).zero?
                        end.map { |b| b[:budget_name] }
    }
  end

  def determine_flow_type(income, spent, transfers_in, transfers_out)
    if income.positive? && transfers_out > (spent + income * 0.5)
      'pass_through' # Recibe y redistribuye
    elsif spent > income + transfers_in
      'deficit'          # Gasta más de lo que recibe
    elsif transfers_in > transfers_out && spent.positive?
      'spending_hub'     # Recibe transferencias para gastar
    else
      'balanced'
    end
  end

  # Necesitas agregar en build_budget_analysis para credit_card:
  def get_current_cycle_info(budget)
    current_cycle = budget.credit_card.credit_card_cycles
                          .where(active: true)
                          .order(cutting_date: :desc)
                          .first

    return unless current_cycle

    {
      cutting_date: current_cycle.cutting_date,
      payment_due_date: current_cycle.payment_due_date,
      days_until_cutting: (current_cycle.cutting_date - Date.current).to_i,
      current_balance: current_cycle.current_balance,
      minimum_payment: current_cycle.minimum_payment,
      cycle_status: current_cycle.status_id
    }
  end

  def calculate_available_funds_for_credit_optimization
    # Efectivo disponible
    cash_available = Budget.joins(:budget_type).where(user_id: @user_id, budget_type: { code: 'cash' })
                           .sum(:current_amount)

    # Ahorros que se pueden usar temporalmente (no toda la meta)
    savings_available = Budget.joins(:savings_fund, :budget_type)
                              .where(user_id: @user_id, budget_type: { code: 'savings_fund' })
                              .where('current_amount > 1000') # Mantener mínimo $1000
                              .sum('current_amount - 1000')

    # Débito disponible
    debit_available = Budget.joins(:budget_type).where(user_id: @user_id, budget_type: { code: 'debit_card' })
                            .where('current_amount > 0')
                            .sum(:current_amount)

    {
      cash: cash_available,
      savings: savings_available,
      debit: debit_available,
      total: cash_available + savings_available + debit_available
    }
  end

  def calculate_optimal_payments
    credit_cards = Budget.joins(:credit_card, :budget_type)
                         .where(user_id: @user_id, active: true, budget_type: { code: 'credit_card' })
                         .includes(credit_card: :credit_card_cycles)

    payment_recommendations = []

    credit_cards.each do |card|
      current_cycle = get_current_cycle_info(card)
      next unless current_cycle && card.credit_card.limit_amount.positive?

      current_balance = current_cycle[:current_balance]
      limit_amount = card.credit_card.limit_amount
      current_utilization = (current_balance / limit_amount * 100)
      target_balance = limit_amount * 0.10 # 10% target
      payment_needed = [current_balance - target_balance, 0].max

      payment_recommendations << {
        card_name: card.name,
        current_balance: current_balance.to_f.round(2),
        current_utilization: current_utilization.round(2),
        target_utilization: 10.0,
        payment_needed: payment_needed.round(2),
        days_until_cutting: current_cycle[:days_until_cutting],
        urgency: determine_urgency(current_cycle[:days_until_cutting], current_utilization)
      }
    end

    payment_recommendations
  end

  def determine_urgency(days_remaining, utilization)
    if days_remaining <= 3 && utilization > 30
      'critical'
    elsif days_remaining <= 7 && utilization > 50
      'high'
    elsif utilization > 70
      'high'
    else
      'medium'
    end
  end

  def calculate_optimal_payment_for_card(budget, cycle_info)
    return nil unless cycle_info || budget.credit_card

    # Usar current_balance del ciclo o del credit_card
    current_balance = cycle_info&.dig(:current_balance) || budget.credit_card&.current_balance || 0
    limit_amount = budget.credit_card&.limit_amount || 0

    return nil if limit_amount.zero?

    target_balance = limit_amount * 0.10 # 10% target
    payment_needed = [current_balance - target_balance, 0].max

    {
      current_balance: current_balance.to_f.round(2),
      target_balance: target_balance.to_f.round(2),
      payment_needed: payment_needed.to_f.round(2),
      current_utilization: (current_balance / limit_amount * 100).round(2),
      target_utilization: 10.0,
      days_until_cutting: cycle_info&.dig(:days_until_cutting) || 0
    }
  end

  def calculate_total_utilization_summary
    credit_cards = Budget.joins(:credit_card, :budget_type)
                         .where(user_id: @user_id, active: true, budget_type: { code: 'credit_card' })
                         .includes(credit_card: :credit_card_cycles)

    total_debt = 0
    total_limit = 0
    cards_over_30 = []
    cards_over_70 = []

    credit_cards.each do |card|
      # Obtener el ciclo activo actual
      current_cycle = card.credit_card.credit_card_cycles
                          .where(active: true)
                          .order(cutting_date: :desc)
                          .first

      next unless current_cycle && card.credit_card.limit_amount.positive?

      current_balance = current_cycle.current_balance
      limit_amount = card.credit_card.limit_amount
      utilization = (current_balance / limit_amount * 100)

      total_debt += current_balance
      total_limit += limit_amount

      cards_over_30 << card.name if utilization > 30
      cards_over_70 << card.name if utilization > 70
    end

    total_utilization = total_limit.positive? ? (total_debt / total_limit * 100).round(2) : 0

    {
      total_utilization:,
      total_debt: total_debt.to_f.round(2),
      total_limit: total_limit.to_f.round(2),
      cards_over_30_percent: cards_over_30,
      cards_over_70_percent: cards_over_70,
      number_of_cards: credit_cards.count
    }
  end

  def build_context
    "You are an expert Credit Score Coach specializing in credit card cycle optimization and strategic payment timing for maximum credit score impact.
    Your expertise lies in analyzing credit card cycles, cutting dates, and payment timing to optimize credit utilization reporting.

    **CREDIT CYCLE INTELLIGENCE:**
    - **Cutting Date Strategy**: Analyze current cycle status and recommend optimal payment timing before cutting dates
    - **Utilization Timing**: Calculate exact payment amounts needed to achieve target utilization at statement generation
    - **Cash Flow Coordination**: Identify available funds across accounts to execute strategic credit card payments
    - **Cycle-Based Planning**: Recommend payment schedules aligned with cutting dates across multiple cards

    **CREDIT SCORE OPTIMIZATION PRIORITIES:**
    1. **PRE-CUTTING DATE ACTIONS**: Urgent payments needed before cutting dates to optimize reported utilization
    2. **CYCLE UTILIZATION TARGETS**: Strategic payment amounts to achieve <10% utilization per card at statement
    3. **CASH FLOW REALLOCATION**: Move funds from savings/debit accounts to optimize credit payments
    4. **MULTI-CARD COORDINATION**: Balance utilization across cards considering different cutting dates
    5. **PAYMENT TIMING OPTIMIZATION**: Schedule payments for maximum score impact

    **CYCLE-AWARE ANALYSIS:**
    - Monitor days remaining until cutting dates
    - Calculate required payment amounts for target utilization
    - Identify cash/savings available for strategic payments
    - Recommend specific transfer amounts and timing
    - Warn about missed optimization opportunities

    **TARGET UTILIZATION STRATEGY:**
    - Individual cards: <10% at statement generation
    - Total portfolio: <30% across all cards
    - Strategic distribution: Spread utilization vs concentrate on low-utilization cards

    Generate 5-7 cycle-aware insights prioritizing immediate cutting date opportunities and strategic payment timing.

    IMPORTANT: Your response must be entirely in Spanish, focusing on actionable payment timing recommendations with specific amounts and dates."
  end

  def build_analysis_prompt
    "Analyze the comprehensive financial data with EXCLUSIVE FOCUS on credit score optimization and strategic payment timing. Generate insights using this credit-focused approach:

    CRITICAL: Respond with PURE JSON only. No markdown code blocks, no explanations outside JSON.
    Start directly with { and end with }.

    **RESPONSE FORMAT (JSON):**
    {
      \"critical_credit_actions\": [
        {
          \"type\": \"cutting_date_urgent|payment_optimization|utilization_critical|score_opportunity\",
          \"title\": \"Action Title in Spanish\",
          \"message\": \"Detailed explanation with specific amounts, dates, and credit score impact in Spanish\",
          \"category\": \"credito\",
          \"priority\": \"urgent|high|medium|low\",
          \"actionable\": \"Specific action with exact amounts and deadlines in Spanish\",
          \"budget_type\": \"credito\",
          \"affected_accounts\": [\"card_names\"],
          \"days_remaining\": 0,
          \"payment_amount\": 0,
          \"current_utilization\": 0,
          \"target_utilization\": 0,
          \"deadline\": \"YYYY-MM-DD\",
          \"credit_score_impact\": \"Expected improvement description in Spanish\"
        }
      ],
      \"utilization_analysis\": {
        \"current_total_utilization\": 0,
        \"target_total_utilization\": \"<30%\",
        \"cards_over_30_percent\": [\"card_names\"],
        \"cards_over_70_percent\": [\"critical_card_names\"],
        \"immediate_payment_needed\": 0,
        \"available_funds_analysis\": \"Breakdown of available cash and savings in Spanish\"
      },
      \"payment_calendar\": [
        {
          \"card_name\": \"name\",
          \"cutting_date\": \"YYYY-MM-DD\",
          \"days_remaining\": 0,
          \"current_balance\": 0,
          \"recommended_payment\": 0,
          \"resulting_utilization\": 0,
          \"urgency_level\": \"critical|high|medium|low\"
        }
      ],
      \"fund_reallocation_strategy\": {
        \"available_cash\": 0,
        \"available_savings\": 0,
        \"suggested_transfers\": [
          {
            \"from_account\": \"source_account_name\",
            \"to_account\": \"credit_card_name\",
            \"amount\": 0,
            \"purpose\": \"utilization_optimization_reason in Spanish\"
          }
        ]
      },
      \"summary\": {
        \"credit_health\": \"Credit utilization, payment timing, and capacity analysis in Spanish\",
        \"cutting_date_urgency\": \"Analysis of approaching cutting dates and required actions in Spanish\",
        \"payment_optimization\": \"Strategic payment recommendations for score improvement in Spanish\",
        \"fund_availability\": \"Available funds for credit optimization in Spanish\",
        \"overall_recommendation\": \"Main credit score improvement strategy prioritizing highest impact actions in Spanish\"
      }
    }

    **CREDIT SCORE COACHING INSTRUCTIONS:**

    **CUTTING DATE URGENCY ANALYSIS:**
    - Prioritize cards with cutting dates in next 7 days as CRITICAL
    - Calculate exact payment amounts needed for 10% utilization target per card
    - Identify available funds from savings/cash accounts for immediate transfers
    - Flag any card over 30% utilization as urgent credit score threat

    **PAYMENT OPTIMIZATION STRATEGY:**
    - Target individual card utilization <10% at statement generation
    - Recommend specific payment amounts and timing for maximum score impact
    - Coordinate payments across multiple cards based on cutting date calendar
    - Suggest fund transfers from savings/cash to optimize credit payments

    **UTILIZATION REBALANCING:**
    - Identify cards with highest utilization needing immediate attention
    - Calculate total available credit capacity across all cards
    - Recommend strategic spending redistribution to maintain low utilization
    - Flag cards approaching limits that could trigger score damage

    **CASH FLOW FOR CREDIT OPTIMIZATION:**
    - Analyze available funds in savings and cash accounts for credit payments
    - Suggest temporary fund reallocation from savings to optimize credit utilization
    - Calculate ROI of using savings to improve credit score
    - Recommend maintaining emergency fund while optimizing credit health

    **TIMELINE-BASED PRIORITIZATION:**
    1. URGENT (1-3 days to cutting): Immediate payment required
    2. HIGH (4-7 days to cutting): Plan payment this week
    3. MEDIUM (8-15 days to cutting): Schedule strategic payment
    4. LOW (>15 days to cutting): Monitor and plan ahead

    **CYCLE-AWARE METRICS TO REFERENCE:**
    - Days remaining until each card's cutting date
    - Current balance vs optimal balance for 10% utilization
    - Available funds in non-credit accounts for strategic payments
    - Payment amounts needed to achieve target utilization before cutting dates
    - Credit score impact timeline for each recommended action

    Focus on actionable credit score recommendations with specific amounts, exact dates, and quantified score impact.
    Prioritize: cutting date urgency > utilization optimization > payment timing > long-term credit strategy.

    RESPOND ONLY WITH THE JSON STRUCTURE ABOVE, NO ADDITIONAL TEXT."
  end
end
