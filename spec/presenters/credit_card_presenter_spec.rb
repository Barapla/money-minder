# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CreditCardPresenter do
  include FinancialTestHelpers

  let(:user) { create(:user) }
  let(:card) { make_credit_card(user:, limit_amount: 21_000, name: 'Klar', cutting_day: 7) }
  let(:budget) { card.budget }
  let(:presenter) { described_class.new(budget) }

  def buy(amount, category: 'Internet y teléfono', on: Date.current)
    make_transaction(user:, budget:, category: category_for(category), amount:,
                     type_code: 'expense', transaction_date: on)
  end

  describe '#utilization_percentage y techo sano' do
    before { buy(3_326.62) }

    it 'calcula la utilización contra el límite' do
      expect(presenter.utilization_percentage).to eq(15.84)
    end

    it 'marca la utilización como sana por debajo del 30%' do
      expect(presenter.utilization_status).to eq(:healthy)
    end

    it 'expone el techo sano como el 30% del límite' do
      expect(presenter.healthy_ceiling).to eq(6_300.0)
    end

    it 'indica cuánto falta para llegar al techo' do
      expect(presenter.room_before_ceiling_formatted).to eq('$2,973.38')
    end
  end

  describe 'cuando la deuda supera el techo sano' do
    before { buy(9_000) }

    it 'no reporta margen restante' do
      expect(presenter.room_before_ceiling_formatted).to be_nil
    end

    it 'marca la utilización como alta' do
      expect(presenter.utilization_status).to eq(:warning)
    end
  end

  describe '#cycle_transactions' do
    before do
      buy(2_172.59)
      buy(1_154.03)
    end

    it 'trae los movimientos ligados al ciclo en curso' do
      expect(presenter.cycle_transactions.size).to eq(2)
    end

    it 'resume la categoría con más gasto del ciclo' do
      top = presenter.top_cycle_category
      expect(top[:name]).to eq('Internet y teléfono')
      expect(top[:percent]).to eq(100)
    end
  end

  describe '#last_cut_utilization' do
    include ActiveSupport::Testing::TimeHelpers

    it 'es nil cuando ningún ciclo ha cortado todavía' do
      card
      expect(presenter.last_cut_utilization).to be_nil
    end

    it 'reporta el uso del corte ya cerrado, sin descontar los pagos posteriores' do
      # Corta el 7: la compra del 1 entra al corte del 07/09 (55% del limite de 21k)
      # y el pago del 10 cae en la ventana, o sea despues de que el corte ya se reporto.
      travel_to(Date.new(2026, 9, 2)) { buy(11_550, on: Date.new(2026, 9, 1)) }
      travel_to(Date.new(2026, 9, 10)) do
        make_transaction(user:, budget:, category: category_for('Pago'), amount: 11_550,
                         type_code: 'income', transaction_date: Date.new(2026, 9, 10))
        entry = described_class.new(Budget.find(budget.id)).last_cut_utilization

        expect(entry[:date]).to eq(Date.new(2026, 9, 7))
        expect(entry[:percent]).to eq(55.0)
        expect(entry[:status]).to eq(:warning)
      end
    end
  end

  describe '#top_cycle_category' do
    it 'retorna nil sin gastos en el ciclo' do
      expect(presenter.top_cycle_category).to be_nil
    end
  end

  describe '#cycle_elapsed_percent' do
    it 'ubica hoy dentro del periodo del ciclo' do
      expect(presenter.cycle_elapsed_percent).to be_between(0, 100)
    end
  end

  describe '#period_start_date' do
    it 'arranca el día siguiente al corte anterior, como el estado de cuenta' do
      expect(presenter.period_start_date).to eq((presenter.cutting_date - 1.month) + 1.day)
    end
  end

  describe '#institution' do
    it 'es nil cuando la tarjeta no tiene producto del catálogo' do
      expect(presenter.institution).to be_nil
    end

    it 'toma la institución del producto asociado' do
      product = FinancialCatalogServices::Registry.by_type(
        FinancialCatalogServices::Registry::CREDIT
      ).to_a.first
      card.update!(financial_product_id: product.id)
      expect(described_class.new(budget.reload).institution).to eq(product.institution)
    end
  end

  describe '#cycle_history' do
    before { buy(3_326.62) }

    it 'marca el ciclo en curso dentro del historial' do
      current = presenter.cycle_history.find { |entry| entry[:current] }
      expect(current[:closing]).to eq(3_326.62)
    end

    it 'expone arrastre, compras, pagos y cierre con monto y formato' do
      entry = presenter.cycle_history.first
      expect(entry).to include(:carried, :carried_formatted, :purchases_formatted,
                               :payments, :payments_formatted, :closing, :closing_formatted)
    end

    it 'cuadra el cierre como arrastre mas compras menos pagos' do
      entry = presenter.cycle_history.find { |item| item[:current] }
      expect(entry[:closing]).to eq(entry[:carried] + entry[:purchases] - entry[:payments])
    end
  end
end
