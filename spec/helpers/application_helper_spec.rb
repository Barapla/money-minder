# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApplicationHelper, type: :helper do
  describe '#financial_institutions_for_select (FEAT-026)' do
    it 'retorna instituciones unicas y ordenadas para el tipo, mas la opcion Otro' do
      options = helper.financial_institutions_for_select(FinancialCatalogServices::Registry::CREDIT)

      expect(options).to include(%w[Nu Nu], %w[Otro other])
      expect(options.last).to eq(%w[Otro other])
    end

    it 'no repite instituciones cuando hay varios productos del mismo banco' do
      options = helper.financial_institutions_for_select(FinancialCatalogServices::Registry::SAVINGS)
      institutions = options.map(&:first) - ['Otro']

      expect(institutions.uniq).to eq(institutions)
    end
  end

  describe '#financial_products_for_select (FEAT-026)' do
    it 'retorna los productos de la institucion filtrados por tipo' do
      options = helper.financial_products_for_select(FinancialCatalogServices::Registry::CREDIT, 'Nu')

      expect(options).to eq([['Nu Credito', 'nu_credit_card']])
    end

    it 'retorna vacio cuando la institucion es other' do
      expect(helper.financial_products_for_select(FinancialCatalogServices::Registry::CREDIT, 'other')).to eq([])
    end

    it 'retorna vacio cuando la institucion es blank' do
      expect(helper.financial_products_for_select(FinancialCatalogServices::Registry::CREDIT, nil)).to eq([])
    end
  end

  describe '#selected_financial_institution (FEAT-026)' do
    it 'retorna la institucion del producto cuando hay financial_product_id' do
      institution = helper.selected_financial_institution(financial_product_id: 'nu_credit_card', persisted: true)

      expect(institution).to eq('Nu')
    end

    it 'retorna other cuando el instrumento ya existe sin financial_product_id' do
      institution = helper.selected_financial_institution(financial_product_id: nil, persisted: true)

      expect(institution).to eq('other')
    end

    it 'retorna nil cuando el instrumento es nuevo y no hay financial_product_id' do
      institution = helper.selected_financial_institution(financial_product_id: nil, persisted: false)

      expect(institution).to be_nil
    end
  end
end
