# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CreditCard, type: :model do
  let(:user) { create(:user) }

  let(:status_group) do
    GroupCatalog.find_or_create_by!(code: 'credit_card_cycle_statuses') { |g| g.name = 'Estados de ciclo' }
  end

  let!(:status_open) do
    Status.find_or_create_by!(code: 'open') do |s|
      s.name = 'Abierto'
      s.color = 'green'
      s.group_catalog = status_group
    end
  end
  let!(:status_closed) do
    Status.find_or_create_by!(code: 'closed') do |s|
      s.name = 'Cerrado'
      s.color = 'gray'
      s.group_catalog = status_group
    end
  end
  let!(:status_pending_payment) do
    Status.find_or_create_by!(code: 'pending_payment') do |s|
      s.name = 'Pendiente de pago'
      s.color = 'yellow'
      s.group_catalog = status_group
    end
  end
  let!(:status_overdue) do
    Status.find_or_create_by!(code: 'overdue') do |s|
      s.name = 'Adeudado'
      s.color = 'red'
      s.group_catalog = status_group
    end
  end

  let(:budget_types_group) do
    GroupCatalog.find_or_create_by!(code: 'budget_types') { |g| g.name = 'Tipos de Presupuesto' }
  end
  let(:credit_card_budget_type) do
    Catalog.find_or_create_by!(code: 'credit_card', group_catalog: budget_types_group) do |c|
      c.value = 'Tarjeta de crédito'
    end
  end

  let(:colors_group) { GroupCatalog.find_or_create_by!(code: 'colors') { |g| g.name = 'Colores' } }
  let(:color) { Catalog.find_or_create_by!(code: 'blue', group_catalog: colors_group) { |c| c.value = 'Azul' } }

  let(:icons_group) { GroupCatalog.find_or_create_by!(code: 'budget_icons') { |g| g.name = 'Iconos' } }
  let(:icon) { Catalog.find_or_create_by!(code: 'card', group_catalog: icons_group) { |c| c.value = 'Card' } }

  let(:transaction_types_group) do
    GroupCatalog.find_or_create_by!(code: 'transaction_types') { |g| g.name = 'Tipos de Transacción' }
  end
  let(:expense_type) do
    Catalog.find_or_create_by!(code: 'expense', group_catalog: transaction_types_group) { |c| c.value = 'Gasto' }
  end
  let(:income_type) do
    Catalog.find_or_create_by!(code: 'income', group_catalog: transaction_types_group) { |c| c.value = 'Ingreso' }
  end

  let(:category) { create(:category) }
  let(:currency) do
    Currency.find_or_create_by!(code: 'MXN') do |c|
      c.name = 'Peso Mexicano'
      c.symbol = '$'
      c.exchange_rate = 1.0
    end
  end

  let(:budget) do
    Budget.create!(
      name: 'Tarjeta de Prueba',
      user: user,
      budget_type: credit_card_budget_type,
      color: color,
      icon: icon,
      current_amount: 0,
      active: true
    )
  end

  def build_credit_card(initial_debt: 0)
    CreditCard.create!(
      budget: budget,
      limit_amount: 20_000,
      initial_debt: initial_debt,
      cutting_day: 15,
      payment_due_days: 5
    )
  end

  def transaction_attrs(credit_card, amount, description, transaction_type) # rubocop:disable Metrics/MethodLength
    {
      user: user,
      budget: credit_card.budget,
      amount: amount,
      description: description,
      transaction_date: Date.current.change(day: 1),
      category: category,
      currency: currency,
      color: color,
      icon: icon,
      transaction_type: transaction_type
    }
  end

  def build_expense(credit_card, amount)
    Transaction.create!(transaction_attrs(credit_card, amount, 'Gasto de prueba', expense_type))
  end

  def build_payment(credit_card, amount)
    Transaction.create!(transaction_attrs(credit_card, amount, 'Pago de prueba', income_type))
  end

  describe 'cálculo de deuda con deuda_inicial (BUG-005)' do
    context 'CA1: deuda_inicial = $5,000 + gasto de $500' do
      it 'deuda total es $5,500' do
        card = build_credit_card(initial_debt: 5_000)
        build_expense(card, 500)
        expect(card.current_cycle.reload.closing_balance).to eq(5_500)
      end
    end

    context 'CA2: deuda_inicial = $10,000 + pago de $2,000' do
      it 'deuda total es $8,000' do
        card = build_credit_card(initial_debt: 10_000)
        build_payment(card, 2_000)
        expect(card.current_cycle.reload.closing_balance).to eq(8_000)
      end
    end

    context 'CA3: sin deuda_inicial' do
      it 'calcula deuda solo con transacciones cuando initial_debt es 0' do
        card = build_credit_card(initial_debt: 0)
        build_expense(card, 1_500)
        build_expense(card, 300)
        expect(card.current_cycle.reload.closing_balance).to eq(1_800)
      end
    end

    context 'CA4: todos los cálculos de deuda reflejan deuda_inicial + transacciones' do
      it 'current_debt incluye deuda_inicial y múltiples transacciones' do
        card = build_credit_card(initial_debt: 5_000)
        build_expense(card, 500)
        build_expense(card, 300)
        build_payment(card, 1_000)
        cycle = card.current_cycle.reload
        expect(cycle.closing_balance).to eq(4_800)
      end
    end

    context 'CA5: eliminar o editar transacciones siempre incluye deuda_inicial' do
      it 'al eliminar un gasto la deuda recalculada incluye deuda_inicial' do
        card = build_credit_card(initial_debt: 5_000)
        gasto = build_expense(card, 500)
        gasto.destroy!
        expect(card.current_cycle.reload.closing_balance).to eq(5_000)
      end

      it 'al editar el monto de un gasto la deuda recalculada incluye deuda_inicial' do
        card = build_credit_card(initial_debt: 5_000)
        gasto = build_expense(card, 500)
        gasto.update!(amount: 300)
        expect(card.current_cycle.reload.closing_balance).to eq(5_300)
      end
    end
  end

  describe 'asociacion a producto del catalogo financiero (FEAT-022)' do
    it 'CA4: autogenera el nombre del budget asociado a partir del producto' do
      card = CreditCard.new(
        budget: budget,
        limit_amount: 20_000,
        initial_debt: 0,
        cutting_day: 15,
        payment_due_days: 5,
        financial_product_id: 'klar_debit_card'
      )

      expect(card).to be_valid
      expect(budget.reload.name).to eq("Cuenta Klar Debito de #{user.first_name}")
    end

    it 'CA4: producto de debito Mercado Pago menciona Mastercard en su descripcion' do
      product = FinancialCatalogServices::Registry.all_products.find { |p| p.id == 'mercado_pago_tarjeta_debito' }

      expect(product.description).to include('Mastercard')
    end

    it 'CA5: producto de credito Mercado Pago usa Visa Classic sin anualidad ni cashback' do
      card = CreditCard.new(
        budget: budget,
        limit_amount: 20_000,
        initial_debt: 0,
        cutting_day: 15,
        payment_due_days: 5,
        financial_product_id: 'mercado_pago_tarjeta_credito'
      )
      product = FinancialCatalogServices::Registry.all_products.find { |p| p.id == 'mercado_pago_tarjeta_credito' }

      expect(card).to be_valid
      expect(budget.reload.name).to eq("Cuenta Tarjeta de crédito Mercado Pago de #{user.first_name}")
      expect(product.network_level).to eq(FinancialNetworks::Visa::Classic)
      expect(product.benefits).to eq([])
    end

    it 'rechaza un financial_product_id que no existe en el catalogo' do
      card = CreditCard.new(
        budget: budget,
        limit_amount: 20_000,
        initial_debt: 0,
        cutting_day: 15,
        payment_due_days: 5,
        financial_product_id: 'no_existe'
      )

      expect(card).to be_invalid
      expect(card.errors[:financial_product_id])
        .to include('no corresponde a ningun producto del catalogo financiero')
    end

    it 'sin financial_product_id es valido y no modifica el nombre del budget' do
      card = build_credit_card(initial_debt: 0)

      expect(budget.reload.name).to eq('Tarjeta de Prueba')
      expect(card.financial_product_id).to be_nil
    end
  end
end
