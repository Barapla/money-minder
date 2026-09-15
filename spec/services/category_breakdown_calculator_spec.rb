# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CategoryBreakdownCalculator do
  let(:user) { create(:user) }
  let(:budget) { make_budget(user:, type_code: 'cash', amount: 0, personal: true) }
  let(:date_range) { Date.current.beginning_of_month..Date.current.end_of_month }

  subject(:calculator) { described_class.new(user, date_range) }

  it 'retorna la distribucion de gastos ordenada por amount DESC con percentage' do
    make_transaction(user:, budget:, category: category_for('Comida'), amount: 600, type_code: 'expense')
    make_transaction(user:, budget:, category: category_for('Transporte'), amount: 400, type_code: 'expense')

    result = calculator.call

    expect(result).to eq(
      [
        { category_name: 'Comida', amount: 600.0, percentage: 60.0 },
        { category_name: 'Transporte', amount: 400.0, percentage: 40.0 }
      ]
    )
  end

  it 'excluye ingresos y transacciones fuera del rango de fechas' do
    make_transaction(user:, budget:, category: category_for('Comida'), amount: 600, type_code: 'expense')
    make_transaction(user:, budget:, category: category_for('Comida'), amount: 5000, type_code: 'income')
    make_transaction(user:, budget:, category: category_for('Comida'), amount: 900, type_code: 'expense',
                     transaction_date: 2.months.ago.to_date)

    result = calculator.call

    expect(result).to eq([{ category_name: 'Comida', amount: 600.0, percentage: 100.0 }])
  end

  it "agrupa bajo 'Sin categoría' cuando category_id no resuelve a una categoria existente" do
    # transactions.category_id es NOT NULL con FK, asi que este caso no ocurre con datos reales;
    # se stubea la consulta agregada para cubrir el fallback definido en la ACs del ticket.
    relation = instance_double(ActiveRecord::Relation)
    allow(user).to receive_message_chain(:transactions, :expense, :where).and_return(relation)
    allow(relation).to receive(:group).with(:category_id).and_return(relation)
    allow(relation).to receive(:sum).with(:amount).and_return({ nil => BigDecimal('500') })

    result = calculator.call

    expect(result).to eq([{ category_name: 'Sin categoría', amount: 500.0, percentage: 100.0 }])
  end

  it 'retorna array vacio cuando no hay gastos' do
    expect(calculator.call).to eq([])
  end
end
