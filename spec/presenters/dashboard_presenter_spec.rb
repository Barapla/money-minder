# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DashboardPresenter do
  include ActiveSupport::Testing::TimeHelpers

  let(:user) { instance_double(User, id: 1) }
  let(:presenter) { described_class.new(user) }

  def credit_card_double(limit_amount:, current_debt:, cutting_day: 15, payment_due_days: 5)
    instance_double(CreditCard,
                    limit_amount: limit_amount,
                    current_debt: current_debt,
                    cutting_day: cutting_day,
                    payment_due_days: payment_due_days)
  end

  def budget_with_card(name:, limit_amount:, current_debt:, cutting_day: 15, payment_due_days: 5)
    card = credit_card_double(limit_amount: limit_amount, current_debt: current_debt,
                              cutting_day: cutting_day, payment_due_days: payment_due_days)
    instance_double(Budget, name: name, credit_card: card)
  end

  describe '#available_balance' do
    before do
      allow(presenter).to receive(:cash_balance).and_return(5_000.0)
      allow(presenter).to receive(:debit_balance).and_return(2_000.0)
      allow(presenter).to receive(:savings_balance).and_return(13_000.0)
    end

    it 'CA1: suma efectivo, débito y fondos de ahorro' do
      expect(presenter.available_balance).to eq(20_000.0)
    end
  end

  describe '#available_balance_formatted' do
    before { allow(presenter).to receive(:available_balance).and_return(20_000.0) }

    it 'incluye símbolo de moneda' do
      expect(presenter.available_balance_formatted).to include('$')
    end
  end

  describe '#balance_breakdown' do
    before do
      allow(presenter).to receive(:cash_balance).and_return(5_000.0)
      allow(presenter).to receive(:debit_balance).and_return(3_000.0)
      allow(presenter).to receive(:debit_breakdown).and_return(
        [{ name: 'Cuenta Nómina', balance: 3_000.0, balance_formatted: '$3,000.00' }]
      )
      allow(presenter).to receive(:savings_balance).and_return(10_000.0)
      allow(presenter).to receive(:savings_breakdown).and_return(
        [{ name: 'Fondo Emergencia', balance: 10_000.0, balance_formatted: '$10,000.00' }]
      )
    end

    it 'CA2: retorna hash con efectivo, débito y ahorros' do
      breakdown = presenter.balance_breakdown
      expect(breakdown[:cash]).to eq(5_000.0)
      expect(breakdown[:debit]).to eq(3_000.0)
      expect(breakdown[:savings]).to eq(10_000.0)
    end

    it 'CA2: incluye desglose de tarjetas de débito' do
      breakdown = presenter.balance_breakdown
      expect(breakdown[:debit_detail].first[:name]).to eq('Cuenta Nómina')
    end

    it 'CA2: incluye desglose de cada fondo' do
      breakdown = presenter.balance_breakdown
      expect(breakdown[:savings_detail].first[:name]).to eq('Fondo Emergencia')
    end

    it 'CA2: incluye valores formateados con símbolo de moneda' do
      breakdown = presenter.balance_breakdown
      expect(breakdown[:cash_formatted]).to include('$')
      expect(breakdown[:debit_formatted]).to include('$')
      expect(breakdown[:savings_formatted]).to include('$')
    end
  end

  describe '#upcoming_card_due_dates' do
    let(:budget_corte25) do
      budget_with_card(name: 'Oro', limit_amount: 10_000, current_debt: 2_000, cutting_day: 25)
    end
    let(:budget_corte10) do
      budget_with_card(name: 'Platinum', limit_amount: 20_000, current_debt: 5_000, cutting_day: 10)
    end

    before do
      allow(presenter).to receive(:credit_card_budgets).and_return([budget_corte25, budget_corte10])
    end

    it 'CA3: retorna array con nombre de tarjeta, fechas, días restantes y deuda' do
      results = presenter.upcoming_card_due_dates
      expect(results).to all(include(:card_name, :cutting_date, :payment_due_date,
                                     :days_until_cutting, :current_debt, :current_debt_formatted))
    end

    it 'CA3: ordena por fecha de corte cronológicamente' do
      results = presenter.upcoming_card_due_dates
      dates = results.map { |r| r[:cutting_date] }
      expect(dates).to eq(dates.sort)
    end

    it 'CA3: retorna todas las tarjetas sin límite' do
      expect(presenter.upcoming_card_due_dates.size).to eq(2)
    end

    it 'incluye la deuda de cada tarjeta' do
      result = presenter.upcoming_card_due_dates.find { |r| r[:card_name] == 'Oro' }
      expect(result[:current_debt]).to eq(2_000.0)
      expect(result[:current_debt_formatted]).to include('$')
    end

    context 'tarjeta sin día de corte configurado' do
      before do
        card_sin_dia = credit_card_double(limit_amount: 5_000, current_debt: 0, cutting_day: nil)
        budget_sin_dia = instance_double(Budget, name: 'Sin corte', credit_card: card_sin_dia)
        allow(presenter).to receive(:credit_card_budgets).and_return([budget_sin_dia])
      end

      it 'omite la tarjeta sin día de corte' do
        expect(presenter.upcoming_card_due_dates).to be_empty
      end
    end

    context 'día de corte 31 en un mes con menos días' do
      it 'retorna una fecha futura válida (último día del mes siguiente)' do
        travel_to Date.new(2026, 1, 31) do
          budget = budget_with_card(name: 'Corte31', limit_amount: 10_000, current_debt: 1_000, cutting_day: 31)
          allow(presenter).to receive(:credit_card_budgets).and_return([budget])
          result = presenter.upcoming_card_due_dates.first
          expect(result[:cutting_date]).to be > Date.current
          expect(result[:cutting_date]).to eq(Date.new(2026, 2, 28))
        end
      end
    end
  end

  describe '#upcoming_payment_dates' do
    it 'CA1: ordena por fecha de pago (no por fecha de corte)' do
      travel_to Date.new(2026, 3, 10) do
        # Corte de este ciclo ya pasó (día 8), pero su pago (día 8 + 25) cae lejos;
        # el próximo corte futuro (abril 8) sí es el más cercano de los dos.
        card_a = budget_with_card(name: 'CorteCercano', limit_amount: 10_000, current_debt: 1_000,
                                  cutting_day: 8, payment_due_days: 25)
        # Corte de este ciclo también pasó (día 9), pero su pago (día 9 + 2) es inminente.
        card_b = budget_with_card(name: 'PagoCercano', limit_amount: 10_000, current_debt: 1_000,
                                  cutting_day: 9, payment_due_days: 2)
        allow(presenter).to receive(:credit_card_budgets).and_return([card_a, card_b])

        results = presenter.upcoming_payment_dates
        expect(results.map { |r| r[:card_name] }).to eq(%w[PagoCercano CorteCercano])
      end
    end

    it 'CA5: usa el corte ya cerrado del ciclo vigente, no el próximo corte futuro' do
      travel_to Date.new(2026, 3, 10) do
        # Hoy es 10, el corte fue el 7 (ya pasó) y el pago es a los 10 días (17).
        # El pago debe caer este mes (17), no el mes siguiente.
        card = budget_with_card(name: 'Visa', limit_amount: 10_000, current_debt: 1_000,
                                cutting_day: 7, payment_due_days: 10)
        allow(presenter).to receive(:credit_card_budgets).and_return([card])

        result = presenter.upcoming_payment_dates.first
        expect(result[:payment_due_date]).to eq(Date.new(2026, 3, 17))
      end
    end

    it 'CA1: limita el resultado a 5 tarjetas' do
      cards = (1..6).map do |i|
        budget_with_card(name: "Tarjeta#{i}", limit_amount: 10_000, current_debt: 100, cutting_day: i + 1)
      end
      allow(presenter).to receive(:credit_card_budgets).and_return(cards)

      expect(presenter.upcoming_payment_dates.size).to eq(5)
    end

    it 'CA4: retorna vacío sin tarjetas de crédito' do
      allow(presenter).to receive(:credit_card_budgets).and_return([])

      expect(presenter.upcoming_payment_dates).to be_empty
    end
  end

  describe '#credit_utilization_alerts' do
    context 'CA4: tarjeta con 50% de utilización' do
      before do
        budget = budget_with_card(name: 'Tarjeta Alta', limit_amount: 10_000,
                                  current_debt: 5_000, cutting_day: 20)
        allow(presenter).to receive(:credit_card_budgets).and_return([budget])
      end

      it 'CA4: genera alerta con porcentaje correcto' do
        alerts = presenter.credit_utilization_alerts
        expect(alerts.first[:utilization_percentage]).to eq(50.0)
      end

      it 'CA4: calcula el pago sugerido para llegar al 30%' do
        # current_balance(5000) - limit(10000)*0.30(3000) = 2000
        alerts = presenter.credit_utilization_alerts
        expect(alerts.first[:suggested_payment]).to eq(2_000.0)
      end

      it 'CA4: incluye fecha de corte en la alerta' do
        alerts = presenter.credit_utilization_alerts
        expect(alerts.first[:cutting_date]).to be_a(Date)
      end

      it 'CA4: incluye monto formateado con símbolo de moneda' do
        alerts = presenter.credit_utilization_alerts
        expect(alerts.first[:suggested_payment_formatted]).to include('$')
      end
    end

    context 'CA5: tarjeta con 25% de utilización' do
      before do
        budget = budget_with_card(name: 'Tarjeta Baja', limit_amount: 10_000,
                                  current_debt: 2_500, cutting_day: 20)
        allow(presenter).to receive(:credit_card_budgets).and_return([budget])
      end

      it 'CA5: no genera alertas' do
        expect(presenter.credit_utilization_alerts).to be_empty
      end
    end

    context 'CA5: tarjeta exactamente al 30%' do
      before do
        budget = budget_with_card(name: 'Justo al limite', limit_amount: 10_000,
                                  current_debt: 3_000, cutting_day: 20)
        allow(presenter).to receive(:credit_card_budgets).and_return([budget])
      end

      it 'CA5: no genera alerta para 30% exacto' do
        expect(presenter.credit_utilization_alerts).to be_empty
      end
    end

    context 'tarjeta con más del 70% de utilización' do
      before do
        budget = budget_with_card(name: 'Critica', limit_amount: 10_000,
                                  current_debt: 8_000, cutting_day: 20)
        allow(presenter).to receive(:credit_card_budgets).and_return([budget])
      end

      it 'marca el estado como :critical' do
        expect(presenter.credit_utilization_alerts.first[:utilization_status]).to eq(:critical)
      end
    end

    context 'tarjeta con 50% de utilización (rango warning)' do
      before do
        budget = budget_with_card(name: 'Warning', limit_amount: 10_000,
                                  current_debt: 5_000, cutting_day: 20)
        allow(presenter).to receive(:credit_card_budgets).and_return([budget])
      end

      it 'marca el estado como :warning para 30-70%' do
        expect(presenter.credit_utilization_alerts.first[:utilization_status]).to eq(:warning)
      end
    end
  end

  describe '#total_debt' do
    context 'CA6: con varias tarjetas con saldo' do
      before do
        b1 = budget_with_card(name: 'Card 1', limit_amount: 10_000, current_debt: 3_500)
        b2 = budget_with_card(name: 'Card 2', limit_amount: 5_000, current_debt: 1_200)
        allow(presenter).to receive(:credit_card_budgets).and_return([b1, b2])
      end

      it 'CA6: suma todos los saldos actuales' do
        expect(presenter.total_debt).to eq(4_700.0)
      end
    end

    context 'CA7: sin tarjetas de crédito' do
      before { allow(presenter).to receive(:credit_card_budgets).and_return([]) }

      it 'retorna 0' do
        expect(presenter.total_debt).to eq(0.0)
      end
    end
  end

  describe '#total_debt_formatted' do
    before { allow(presenter).to receive(:total_debt).and_return(4_700.0) }

    it 'formatea la deuda con símbolo de moneda' do
      formatted = presenter.total_debt_formatted
      expect(formatted).to include('$')
      expect(formatted).to include('4')
    end
  end

  describe '#debt_breakdown' do
    context 'con tarjetas con y sin saldo' do
      before do
        b1 = budget_with_card(name: 'Con Saldo', limit_amount: 10_000, current_debt: 3_500)
        b2 = budget_with_card(name: 'Sin Saldo', limit_amount: 5_000, current_debt: 0)
        allow(presenter).to receive(:credit_card_budgets).and_return([b1, b2])
      end

      it 'incluye solo tarjetas con saldo mayor a cero' do
        result = presenter.debt_breakdown
        expect(result.size).to eq(1)
        expect(result.first[:card_name]).to eq('Con Saldo')
        expect(result.first[:debt]).to eq(3_500.0)
        expect(result.first[:debt_formatted]).to include('$')
      end
    end

    context 'CA7: sin tarjetas de crédito' do
      before { allow(presenter).to receive(:credit_card_budgets).and_return([]) }

      it 'retorna array vacío' do
        expect(presenter.debt_breakdown).to be_empty
      end
    end
  end

  describe '#credit_cards?' do
    context 'CA7: sin tarjetas' do
      before { allow(presenter).to receive(:credit_card_budgets).and_return([]) }

      it 'CA7: retorna false' do
        expect(presenter.credit_cards?).to be false
      end
    end

    context 'con al menos una tarjeta' do
      before do
        budget = budget_with_card(name: 'Card', limit_amount: 10_000, current_debt: 0)
        allow(presenter).to receive(:credit_card_budgets).and_return([budget])
      end

      it 'retorna true' do
        expect(presenter.credit_cards?).to be true
      end
    end
  end

  describe '#savings_funds?' do
    context 'CA8: sin fondos de ahorro' do
      before { allow(presenter).to receive(:active_savings_funds).and_return([]) }

      it 'CA8: retorna false' do
        expect(presenter.savings_funds?).to be false
      end
    end

    context 'con fondos de ahorro' do
      before do
        sf = instance_double(SavingsFund)
        allow(presenter).to receive(:active_savings_funds).and_return([sf])
      end

      it 'retorna true' do
        expect(presenter.savings_funds?).to be true
      end
    end
  end

  describe '#debit_cards?' do
    context 'sin tarjetas de débito' do
      before { allow(presenter).to receive(:active_debit_budgets).and_return([]) }

      it 'retorna false' do
        expect(presenter.debit_cards?).to be false
      end
    end

    context 'con al menos una tarjeta de débito' do
      before do
        budget = instance_double(Budget)
        allow(presenter).to receive(:active_debit_budgets).and_return([budget])
      end

      it 'retorna true' do
        expect(presenter.debit_cards?).to be true
      end
    end
  end

  describe '#payroll_configured?' do
    context 'CA3: sin employment_information' do
      before do
        allow(user).to receive(:employment_information).and_return(nil)
        allow(user).to receive(:payroll_profile).and_return(nil)
      end

      it 'CA3: retorna false' do
        expect(presenter.payroll_configured?).to be false
      end
    end

    context 'con employment_information pero sin payroll_profile' do
      before do
        allow(user).to receive(:employment_information).and_return(instance_double(EmploymentInformation))
        allow(user).to receive(:payroll_profile).and_return(nil)
      end

      it 'retorna false' do
        expect(presenter.payroll_configured?).to be false
      end
    end

    context 'CA2: con employment_information y payroll_profile' do
      before do
        allow(user).to receive(:employment_information).and_return(instance_double(EmploymentInformation))
        allow(user).to receive(:payroll_profile).and_return(instance_double(PayrollProfile))
      end

      it 'CA2: retorna true' do
        expect(presenter.payroll_configured?).to be true
      end
    end
  end

  describe '#next_payroll_info' do
    context 'CA3: sin información de nómina configurada' do
      before { allow(presenter).to receive(:payroll_configured?).and_return(false) }

      it 'CA3: retorna nil' do
        expect(presenter.next_payroll_info).to be_nil
      end
    end

    context 'CA2: con nómina configurada y pago en más de 7 días' do
      let(:reminder) do
        instance_double(PayrollReminder,
                        date: Date.current + 15,
                        net_amount: 25_000.0,
                        periodicity_label: 'Quincena',
                        next_period_label: 'Próxima quincena')
      end
      let(:generator) { instance_double(PayrollServices::ReminderGenerator) }

      before do
        allow(presenter).to receive(:payroll_configured?).and_return(true)
        allow(PayrollServices::ReminderGenerator).to receive(:new).with(user).and_return(generator)
        allow(generator).to receive(:generate).and_return([reminder])
      end

      it 'CA2: retorna hash con monto neto y fecha de pago' do
        info = presenter.next_payroll_info
        expect(info[:net_amount]).to eq(25_000.0)
        expect(info[:payment_date]).to eq(Date.current + 15)
      end

      it 'CA2: coming_soon es false si faltan más de 7 días' do
        expect(presenter.next_payroll_info[:coming_soon]).to be false
      end

      it 'incluye monto formateado con símbolo de moneda' do
        expect(presenter.next_payroll_info[:net_amount_formatted]).to include('$')
      end

      it 'CA2: incluye periodicity_label de la quincena' do
        expect(presenter.next_payroll_info[:periodicity_label]).to eq('Quincena')
      end

      it 'CA2: incluye next_period_label de la quincena' do
        expect(presenter.next_payroll_info[:next_period_label]).to eq('Próxima quincena')
      end
    end

    context 'CA1: usuario con pago semanal' do
      let(:reminder) do
        instance_double(PayrollReminder,
                        date: Date.current + 4,
                        net_amount: 7_000.0,
                        periodicity_label: 'Pago semanal',
                        next_period_label: 'Próximo pago semanal')
      end
      let(:generator) { instance_double(PayrollServices::ReminderGenerator) }

      before do
        allow(presenter).to receive(:payroll_configured?).and_return(true)
        allow(PayrollServices::ReminderGenerator).to receive(:new).with(user).and_return(generator)
        allow(generator).to receive(:generate).and_return([reminder])
      end

      it 'CA1: incluye next_period_label semanal' do
        expect(presenter.next_payroll_info[:next_period_label]).to eq('Próximo pago semanal')
      end

      it 'CA1: incluye periodicity_label semanal' do
        expect(presenter.next_payroll_info[:periodicity_label]).to eq('Pago semanal')
      end
    end

    context 'CA3: usuario con pago mensual' do
      let(:reminder) do
        instance_double(PayrollReminder,
                        date: Date.current + 20,
                        net_amount: 30_000.0,
                        periodicity_label: 'Pago mensual',
                        next_period_label: 'Próximo pago mensual')
      end
      let(:generator) { instance_double(PayrollServices::ReminderGenerator) }

      before do
        allow(presenter).to receive(:payroll_configured?).and_return(true)
        allow(PayrollServices::ReminderGenerator).to receive(:new).with(user).and_return(generator)
        allow(generator).to receive(:generate).and_return([reminder])
      end

      it 'CA3: incluye next_period_label mensual' do
        expect(presenter.next_payroll_info[:next_period_label]).to eq('Próximo pago mensual')
      end
    end

    context 'CA8: con pago en 5 días o menos' do
      let(:reminder) do
        instance_double(PayrollReminder,
                        date: Date.current + 5,
                        net_amount: 25_000.0,
                        periodicity_label: 'Quincena',
                        next_period_label: 'Próxima quincena')
      end
      let(:generator) { instance_double(PayrollServices::ReminderGenerator) }

      before do
        allow(presenter).to receive(:payroll_configured?).and_return(true)
        allow(PayrollServices::ReminderGenerator).to receive(:new).with(user).and_return(generator)
        allow(generator).to receive(:generate).and_return([reminder])
      end

      it 'CA8: coming_soon es true si faltan 7 días o menos' do
        expect(presenter.next_payroll_info[:coming_soon]).to be true
      end
    end

    context 'sin recordatorios próximos' do
      let(:generator) { instance_double(PayrollServices::ReminderGenerator) }

      before do
        allow(presenter).to receive(:payroll_configured?).and_return(true)
        allow(PayrollServices::ReminderGenerator).to receive(:new).with(user).and_return(generator)
        allow(generator).to receive(:generate).and_return([])
      end

      it 'retorna nil cuando no hay pagos próximos' do
        expect(presenter.next_payroll_info).to be_nil
      end
    end
  end

  describe '#monthly_budget_summary' do
    context 'CA5: sin transacciones de gasto en el mes' do
      before do
        allow(presenter).to receive(:monthly_budget_summary).and_call_original
        transactions_scope = instance_double(ActiveRecord::Relation)
        allow(user).to receive(:transactions).and_return(transactions_scope)
        allow(transactions_scope).to receive(:joins).and_return(transactions_scope)
        allow(transactions_scope).to receive(:where).and_return(transactions_scope)
        allow(transactions_scope).to receive(:group).and_return(transactions_scope)
        allow(transactions_scope).to receive(:sum).and_return({})
      end

      it 'CA5: retorna array vacío' do
        expect(presenter.monthly_budget_summary).to be_empty
      end
    end

    context 'CA4: con gastos por categoría' do
      before do
        allow(presenter).to receive(:build_budget_summary).and_call_original
        rows = {
          [1, 'Alimentación'] => 5_000.0,
          [2, 'Transporte'] => 2_000.0,
          [3, 'Entretenimiento'] => 500.0
        }
        allow(presenter).to receive(:monthly_budget_summary).and_call_original
        transactions_scope = instance_double(ActiveRecord::Relation)
        allow(user).to receive(:transactions).and_return(transactions_scope)
        allow(transactions_scope).to receive(:joins).and_return(transactions_scope)
        allow(transactions_scope).to receive(:where).and_return(transactions_scope)
        allow(transactions_scope).to receive(:group).and_return(transactions_scope)
        allow(transactions_scope).to receive(:sum).and_return(rows)
      end

      it 'CA4: retorna categorías ordenadas de mayor a menor gasto' do
        result = presenter.monthly_budget_summary
        amounts = result.map { |r| r[:amount] }
        expect(amounts).to eq(amounts.sort.reverse)
      end

      it 'CA4: incluye campos requeridos por la vista' do
        result = presenter.monthly_budget_summary
        expect(result.first).to include(:category_name, :amount, :amount_formatted,
                                        :progress_percent, :status)
      end

      it 'CA4: la categoría con mayor gasto tiene 100% de progreso' do
        result = presenter.monthly_budget_summary
        expect(result.first[:progress_percent]).to eq(100)
      end

      it 'CA4: asigna status :safe a categorías con menos del 70% del máximo' do
        result = presenter.monthly_budget_summary
        low_item = result.last
        expect(low_item[:status]).to eq(:safe)
      end
    end
  end

  describe '#recurring_expenses_summary' do
    def rt_double(frequency:, amount:)
      instance_double(RecurringTransaction,
                      frequency: frequency,
                      transaction_options: { 'amount' => amount.to_s })
    end

    context 'CA1: sin transacciones recurrentes activas' do
      before { allow(presenter).to receive(:active_recurring_expenses).and_return([]) }

      it 'CA1: retorna count 0 y monthly_total 0' do
        summary = presenter.recurring_expenses_summary
        expect(summary[:count]).to eq(0)
        expect(summary[:monthly_total]).to eq(0)
      end
    end

    context 'CA1: con gastos de distintas frecuencias' do
      before do
        rts = [
          rt_double(frequency: 'monthly', amount: 100),
          rt_double(frequency: 'weekly', amount: 20),
          rt_double(frequency: 'bi_weekly', amount: 50)
        ]
        allow(presenter).to receive(:active_recurring_expenses).and_return(rts)
      end

      it 'CA1: retorna count correcto' do
        expect(presenter.recurring_expenses_summary[:count]).to eq(3)
      end

      it 'CA1: calcula total mensual con factores correctos (100 + 20*4.33 + 50*2.17)' do
        expected = 100 + (20 * 4.33) + (50 * 2.17)
        expect(presenter.recurring_expenses_summary[:monthly_total]).to be_within(0.01).of(expected)
      end
    end

    context 'CA5: con transacciones de tipo income' do
      before { allow(presenter).to receive(:active_recurring_expenses).and_return([]) }

      it 'CA5: no cuenta transacciones income (filtradas en active_recurring_expenses)' do
        expect(presenter.recurring_expenses_summary[:count]).to eq(0)
      end
    end

    context 'con frecuencia daily' do
      before do
        allow(presenter).to receive(:active_recurring_expenses)
          .and_return([rt_double(frequency: 'daily', amount: 10)])
      end

      it 'multiplica por 30 para monthly_total' do
        expect(presenter.recurring_expenses_summary[:monthly_total]).to be_within(0.01).of(300)
      end
    end

    context 'con frecuencia quarterly' do
      before do
        allow(presenter).to receive(:active_recurring_expenses)
          .and_return([rt_double(frequency: 'quarterly', amount: 300)])
      end

      it 'divide entre 3 para monthly_total' do
        expect(presenter.recurring_expenses_summary[:monthly_total]).to be_within(0.01).of(100)
      end
    end

    context 'con frecuencia annually' do
      before do
        allow(presenter).to receive(:active_recurring_expenses)
          .and_return([rt_double(frequency: 'annually', amount: 1200)])
      end

      it 'divide entre 12 para monthly_total' do
        expect(presenter.recurring_expenses_summary[:monthly_total]).to be_within(0.01).of(100)
      end
    end
  end

  describe '#recurring_expenses?' do
    context 'sin gastos recurrentes' do
      before { allow(presenter).to receive(:active_recurring_expenses).and_return([]) }

      it 'retorna false' do
        expect(presenter.recurring_expenses?).to be false
      end
    end

    context 'con gastos recurrentes' do
      before do
        rt = instance_double(RecurringTransaction,
                             frequency: 'monthly',
                             transaction_options: { 'amount' => '100' })
        allow(presenter).to receive(:active_recurring_expenses).and_return([rt])
      end

      it 'retorna true' do
        expect(presenter.recurring_expenses?).to be true
      end
    end
  end

  describe '#upcoming_obligatory_payments' do
    def op_with_recurrence(name:, amount:, dates:)
      recurrence = instance_double(Recurrence)
      allow(recurrence).to receive(:occurrences_in_range).and_return(dates)
      instance_double(ObligatoryPayment, name: name, amount: amount, recurrence: recurrence)
    end

    def op_without_recurrence(name: 'Pago', amount: 100)
      instance_double(ObligatoryPayment, name: name, amount: amount, recurrence: nil)
    end

    def stub_obligatory_payments(ops)
      relation = instance_double(ActiveRecord::Relation)
      allow(relation).to receive(:includes).and_return(ops)
      allow(user).to receive(:obligatory_payments).and_return(relation)
    end

    context 'sin pagos obligatorios' do
      before { stub_obligatory_payments([]) }

      it 'retorna array vacío' do
        expect(presenter.upcoming_obligatory_payments).to be_empty
      end
    end

    context 'con un pago mensual próximo' do
      let(:date_in_range) { Date.current + 5 }
      let(:op) { op_with_recurrence(name: 'Renta', amount: 5000, dates: [date_in_range]) }

      before { stub_obligatory_payments([op]) }

      it 'incluye los campos requeridos' do
        payment = presenter.upcoming_obligatory_payments.first
        expect(payment).to include(:date, :description, :amount, :amount_formatted)
      end

      it 'la fecha está dentro de los próximos 30 días' do
        expect(presenter.upcoming_obligatory_payments.first[:date]).to be <= Date.current + 30
      end

      it 'usa el nombre del pago obligatorio como descripción' do
        expect(presenter.upcoming_obligatory_payments.first[:description]).to eq('Renta')
      end
    end

    context 'ordena cronológicamente' do
      before do
        ops = [
          op_with_recurrence(name: 'Ultimo', amount: 100, dates: [Date.current + 20]),
          op_with_recurrence(name: 'Primero', amount: 200, dates: [Date.current + 3]),
          op_with_recurrence(name: 'Medio', amount: 150, dates: [Date.current + 10])
        ]
        stub_obligatory_payments(ops)
      end

      it 'ordena por fecha ascendente' do
        dates = presenter.upcoming_obligatory_payments.map { |p| p[:date] }
        expect(dates).to eq(dates.sort)
      end
    end

    context 'con más de 10 ocurrencias en 30 días' do
      before do
        many_dates = (1..15).map { |i| Date.current + i }
        ops = [op_with_recurrence(name: 'Diario', amount: 50, dates: many_dates)]
        stub_obligatory_payments(ops)
      end

      it 'limita a 10 items' do
        expect(presenter.upcoming_obligatory_payments.size).to be <= 10
      end
    end

    context 'pago sin recurrencia configurada' do
      before { stub_obligatory_payments([op_without_recurrence]) }

      it 'omite el pago sin recurrencia' do
        expect(presenter.upcoming_obligatory_payments).to be_empty
      end
    end

    context 'recurrencia sin fechas en el rango' do
      let(:op) { op_with_recurrence(name: 'Anual', amount: 1000, dates: []) }

      before { stub_obligatory_payments([op]) }

      it 'retorna array vacío cuando no hay fechas en el rango' do
        expect(presenter.upcoming_obligatory_payments).to be_empty
      end
    end
  end

  describe '#monthly_budget_summary?' do
    context 'CA5: sin datos' do
      before { allow(presenter).to receive(:monthly_budget_summary).and_return([]) }

      it 'CA5: retorna false' do
        expect(presenter.monthly_budget_summary?).to be false
      end
    end

    context 'CA4: con datos' do
      before do
        allow(presenter).to receive(:monthly_budget_summary).and_return(
          [{ category_name: 'Test', amount: 100, amount_formatted: '$100.00',
             progress_percent: 100, status: :danger }]
        )
      end

      it 'CA4: retorna true' do
        expect(presenter.monthly_budget_summary?).to be true
      end
    end
  end
end
