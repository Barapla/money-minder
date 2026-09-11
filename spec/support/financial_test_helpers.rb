# frozen_string_literal: true

# Helpers compartidos para construir catalogos y presupuestos en specs de
# servicios financieros (chatbot, saving goals, etc.) sin depender de seeds.
module FinancialTestHelpers
  def budget_types_group
    GroupCatalog.find_or_create_by!(code: 'budget_types') { |g| g.name = 'budget_types' }
  end

  def transaction_types_group
    GroupCatalog.find_or_create_by!(code: 'transaction_types') { |g| g.name = 'transaction_types' }
  end

  def color_catalog
    color_group = GroupCatalog.find_or_create_by!(code: 'colors') { |g| g.name = 'colors' }
    Catalog.find_or_create_by!(code: 'purple', group_catalog: color_group) { |c| c.value = 'Purple' }
  end

  def icon_catalog
    icon_group = GroupCatalog.find_or_create_by!(code: 'budget_icons') { |g| g.name = 'budget_icons' }
    Catalog.find_or_create_by!(code: 'cash', group_catalog: icon_group) { |c| c.value = 'Cash' }
  end

  def budget_type_for(code)
    Catalog.find_or_create_by!(code:, group_catalog: budget_types_group) { |c| c.value = code }
  end

  def transaction_type_for(code)
    Catalog.find_or_create_by!(code:, group_catalog: transaction_types_group) { |c| c.value = code }
  end

  def frequency_types_group
    GroupCatalog.find_or_create_by!(code: 'frequency_types') { |g| g.name = 'frequency_types' }
  end

  def frequency_type_for(code)
    Catalog.find_or_create_by!(code:, group_catalog: frequency_types_group) { |c| c.value = code }
  end

  def make_obligatory_payment(user:, amount:, recurring: false, frequency_code: 'monthly', frequency_value: 1, # rubocop:disable Metrics/ParameterLists
                              reminder_type: 'payment', due_date: Date.current + 5.days)
    payment = ObligatoryPayment.new(
      user:, name: 'Pago de prueba', amount:, reminder_type:,
      category: category_for('Servicios'), color: color_catalog, icon: icon_catalog,
      due_date: recurring ? nil : due_date
    )
    build_payment_recurrence(payment, frequency_code, frequency_value) if recurring
    payment.save!
    payment
  end

  def build_payment_recurrence(payment, frequency_code, frequency_value)
    payment.build_recurrence(
      recurrenceable_type_catalog: FactoryBot.create(:catalog),
      frequency_type: frequency_type_for(frequency_code),
      frequency_value:,
      start_date: Date.current
    )
  end

  def category_for(name, parent: nil)
    Category.find_or_create_by!(name: name) { |c| c.parent_category = parent }
  end

  def make_budget(user:, type_code:, amount:, personal: false, name: nil)
    Budget.create!(
      name: name || "Budget #{type_code}",
      user:,
      budget_type: budget_type_for(type_code),
      color: color_catalog,
      icon: icon_catalog,
      current_amount: amount,
      personal:,
      active: true
    )
  end

  STATUS_SEEDS = {
    'open' => %w[Abierto green], 'closed' => %w[Cerrado gray],
    'pending_payment' => ['Pendiente de pago', 'yellow'], 'overdue' => %w[Adeudado red]
  }.freeze

  def seed_credit_card_statuses!
    group = GroupCatalog.find_or_create_by!(code: 'credit_card_cycle_statuses') { |g| g.name = 'Estados de ciclo' }
    STATUS_SEEDS.each do |code, (name, color)|
      Status.find_or_create_by!(code:) do |status|
        status.name = name
        status.color = color
        status.group_catalog = group
      end
    end
  end

  def make_credit_card(user:, limit_amount:, name: 'Tarjeta de prueba', cutting_day: 15)
    seed_credit_card_statuses!
    budget = make_budget(user:, type_code: 'credit_card', amount: 0, name:)
    # Budget#build_budget_type_if_needed ya autoconstruye y guarda un CreditCard en
    # blanco al crear el Budget; reutilizarlo evita un segundo registro huerfano
    # apuntando al mismo budget_id (has_one sin unicidad en BD).
    card = budget.credit_card || budget.build_credit_card
    card.update!(limit_amount:, initial_debt: 0, cutting_day:, payment_due_days: 5)
    card
  end

  def make_recurring_transaction(user:, type_code:, amount:, frequency: 'monthly')
    RecurringTransaction.create!(
      user:, frequency:, start_date: Date.current,
      transaction_options: { 'transaction_type_id' => transaction_type_for(type_code).id.to_s, 'amount' => amount.to_s }
    )
  end

  def make_transaction(user:, budget:, category:, amount:, type_code:)
    Transaction.create!(
      user:, budget:, category:,
      amount:,
      transaction_type: transaction_type_for(type_code),
      color: color_catalog,
      icon: icon_catalog,
      currency: Currency.default || FactoryBot.create(:currency),
      transaction_date: Date.current
    )
  end
end
