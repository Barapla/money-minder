# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DashboardPresenter do
  let(:user) { instance_double(User, id: 1) }
  let(:presenter) { described_class.new(user) }

  def credit_card_double(limit_amount:, current_balance:, cutting_day: 15, payment_due_days: 5)
    instance_double(CreditCard,
                    limit_amount: limit_amount,
                    current_balance: current_balance,
                    cutting_day: cutting_day,
                    payment_due_days: payment_due_days)
  end

  def budget_with_card(name:, limit_amount:, current_balance:, cutting_day: 15, payment_due_days: 5)
    card = credit_card_double(limit_amount: limit_amount, current_balance: current_balance,
                              cutting_day: cutting_day, payment_due_days: payment_due_days)
    instance_double(Budget, name: name, credit_card: card)
  end

  describe '#available_balance' do
    before do
      allow(presenter).to receive(:cash_balance).and_return(5_000.0)
      allow(presenter).to receive(:savings_balance).and_return(13_000.0)
    end

    it 'CA1: suma efectivo más fondos de ahorro' do
      expect(presenter.available_balance).to eq(18_000.0)
    end
  end

  describe '#available_balance_formatted' do
    before { allow(presenter).to receive(:available_balance).and_return(18_000.0) }

    it 'incluye símbolo de moneda' do
      expect(presenter.available_balance_formatted).to include('$')
    end
  end

  describe '#balance_breakdown' do
    before do
      allow(presenter).to receive(:cash_balance).and_return(5_000.0)
      allow(presenter).to receive(:savings_balance).and_return(10_000.0)
      allow(presenter).to receive(:savings_breakdown).and_return(
        [{ name: 'Fondo Emergencia', balance: 10_000.0, balance_formatted: '$10,000.00' }]
      )
    end

    it 'CA2: retorna hash con efectivo y ahorros' do
      breakdown = presenter.balance_breakdown
      expect(breakdown[:cash]).to eq(5_000.0)
      expect(breakdown[:savings]).to eq(10_000.0)
    end

    it 'CA2: incluye desglose de cada fondo' do
      breakdown = presenter.balance_breakdown
      expect(breakdown[:savings_detail].first[:name]).to eq('Fondo Emergencia')
    end

    it 'CA2: incluye valores formateados con símbolo de moneda' do
      breakdown = presenter.balance_breakdown
      expect(breakdown[:cash_formatted]).to include('$')
      expect(breakdown[:savings_formatted]).to include('$')
    end
  end

  describe '#upcoming_card_due_dates' do
    let(:budget_corte25) do
      budget_with_card(name: 'Oro', limit_amount: 10_000, current_balance: 2_000, cutting_day: 25)
    end
    let(:budget_corte10) do
      budget_with_card(name: 'Platinum', limit_amount: 20_000, current_balance: 5_000, cutting_day: 10)
    end

    before do
      allow(presenter).to receive(:credit_card_budgets).and_return([budget_corte25, budget_corte10])
    end

    it 'CA3: retorna array con nombre de tarjeta, fechas y días restantes' do
      results = presenter.upcoming_card_due_dates
      expect(results).to all(include(:card_name, :cutting_date, :payment_due_date, :days_until_cutting))
    end

    it 'CA3: ordena por fecha de corte cronológicamente' do
      results = presenter.upcoming_card_due_dates
      dates = results.map { |r| r[:cutting_date] }
      expect(dates).to eq(dates.sort)
    end

    it 'CA3: respeta el límite de 5 tarjetas' do
      expect(presenter.upcoming_card_due_dates.size).to be <= 5
    end

    it 'aplica el límite personalizado' do
      expect(presenter.upcoming_card_due_dates(limit: 1).size).to eq(1)
    end

    context 'tarjeta sin día de corte configurado' do
      before do
        card_sin_dia = credit_card_double(limit_amount: 5_000, current_balance: 0, cutting_day: nil)
        budget_sin_dia = instance_double(Budget, name: 'Sin corte', credit_card: card_sin_dia)
        allow(presenter).to receive(:credit_card_budgets).and_return([budget_sin_dia])
      end

      it 'omite la tarjeta sin día de corte' do
        expect(presenter.upcoming_card_due_dates).to be_empty
      end
    end
  end

  describe '#credit_utilization_alerts' do
    context 'CA4: tarjeta con 50% de utilización' do
      before do
        budget = budget_with_card(name: 'Tarjeta Alta', limit_amount: 10_000,
                                  current_balance: 5_000, cutting_day: 20)
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
                                  current_balance: 2_500, cutting_day: 20)
        allow(presenter).to receive(:credit_card_budgets).and_return([budget])
      end

      it 'CA5: no genera alertas' do
        expect(presenter.credit_utilization_alerts).to be_empty
      end
    end

    context 'CA5: tarjeta exactamente al 30%' do
      before do
        budget = budget_with_card(name: 'Justo al limite', limit_amount: 10_000,
                                  current_balance: 3_000, cutting_day: 20)
        allow(presenter).to receive(:credit_card_budgets).and_return([budget])
      end

      it 'CA5: no genera alerta para 30% exacto' do
        expect(presenter.credit_utilization_alerts).to be_empty
      end
    end

    context 'tarjeta con más del 70% de utilización' do
      before do
        budget = budget_with_card(name: 'Critica', limit_amount: 10_000,
                                  current_balance: 8_000, cutting_day: 20)
        allow(presenter).to receive(:credit_card_budgets).and_return([budget])
      end

      it 'marca el estado como :critical' do
        expect(presenter.credit_utilization_alerts.first[:utilization_status]).to eq(:critical)
      end
    end

    context 'tarjeta con 50% de utilización (rango warning)' do
      before do
        budget = budget_with_card(name: 'Warning', limit_amount: 10_000,
                                  current_balance: 5_000, cutting_day: 20)
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
        b1 = budget_with_card(name: 'Card 1', limit_amount: 10_000, current_balance: 3_500)
        b2 = budget_with_card(name: 'Card 2', limit_amount: 5_000, current_balance: 1_200)
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

  describe '#credit_cards?' do
    context 'CA7: sin tarjetas' do
      before { allow(presenter).to receive(:credit_card_budgets).and_return([]) }

      it 'CA7: retorna false' do
        expect(presenter.credit_cards?).to be false
      end
    end

    context 'con al menos una tarjeta' do
      before do
        budget = budget_with_card(name: 'Card', limit_amount: 10_000, current_balance: 0)
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
end
