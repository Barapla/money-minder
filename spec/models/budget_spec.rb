# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Budget, type: :model do
  let(:user) { create(:user, first_name: 'Bryan') }
  let(:budget_type) { create(:catalog) }
  let(:color) { create(:catalog) }
  let(:icon) { create(:catalog) }
  let(:invalid_product_message) { 'no corresponde a ningun producto del catalogo financiero' }

  def build_budget(attrs = {})
    Budget.new(
      {
        user:,
        budget_type:,
        color:,
        icon:,
        current_amount: 0
      }.merge(attrs)
    )
  end

  describe 'sin financial_product_id (CA1)' do
    it 'permite un nombre manual y financial_product_id queda nil' do
      budget = build_budget(name: 'Efectivo de Bryan')

      expect(budget).to be_valid
      expect(budget.financial_product_id).to be_nil
      expect(budget.name).to eq('Efectivo de Bryan')
    end
  end

  describe 'con financial_product_id valido (CA2)' do
    it 'autogenera el nombre a partir del producto del catalogo' do
      budget = build_budget(name: 'nombre que sera reemplazado', financial_product_id: 'nu_credit_card')

      expect(budget).to be_valid
      expect(budget.name).to eq('Cuenta Nu Credito de Bryan')
    end
  end

  describe 'con financial_product_id invalido (CA3)' do
    it 'falla la validacion con un mensaje claro' do
      budget = build_budget(name: 'X', financial_product_id: 'no_existe_en_el_catalogo')

      expect(budget).to be_invalid
      expect(budget.errors[:financial_product_id]).to include(invalid_product_message)
    end
  end

  describe 'con Registry vacio' do
    it 'rechaza cualquier financial_product_id' do
      allow(FinancialCatalogServices::Registry).to receive(:all_products).and_return([])

      budget = build_budget(name: 'X', financial_product_id: 'nu_credit_card')

      expect(budget).to be_invalid
      expect(budget.errors[:financial_product_id]).to include(invalid_product_message)
    end
  end

  describe 'actualizando un budget existente (CA8)' do
    it 'regenera el nombre automaticamente al guardar' do
      budget = build_budget(name: 'Efectivo de Bryan')
      budget.save!

      budget.update!(financial_product_id: 'klar_debit_card')

      expect(budget.reload.name).to eq('Cuenta Klar Debito de Bryan')
    end
  end
end
