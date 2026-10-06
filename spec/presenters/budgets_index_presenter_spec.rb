# frozen_string_literal: true

require 'rails_helper'

# La barra verde/roja del patrimonio reparte el ancho entre lo que tienes y lo
# que debes. Es la unica aritmetica del presenter que no cae en otro spec.
RSpec.describe BudgetsIndexPresenter do
  subject(:presenter) { described_class.new(create(:user)) }

  describe '#money_share_of_total' do
    it 'reparte el ancho entre dinero y deuda' do
      allow(presenter).to receive_messages(money_total: 10_000.0, debt_total: 5_000.0)

      expect(presenter.money_share_of_total).to eq(66.7)
    end

    it 'da la barra entera al dinero cuando no debes nada' do
      allow(presenter).to receive_messages(money_total: 10_000.0, debt_total: 0.0)

      expect(presenter.money_share_of_total).to eq(100.0)
    end

    # Sin cuentas no hay nada que repartir: la barra va llena en verde y no en
    # rojo, que es lo que se leeria como "todo lo tuyo es deuda".
    it 'no divide entre cero cuando no hay cuentas' do
      allow(presenter).to receive_messages(money_total: 0.0, debt_total: 0.0)

      expect(presenter.money_share_of_total).to eq(100.0)
    end
  end
end
