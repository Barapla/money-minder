# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FinancialCatalogServices::Registry do
  describe '.all_products' do
    it 'returns every product in the catalog' do
      expect(described_class.all_products).to contain_exactly(
        an_instance_of(FinancialCatalogServices::Nu::NuCreditCard),
        an_instance_of(FinancialCatalogServices::Klar::KlarDebitCard),
        an_instance_of(FinancialCatalogServices::Bbva::BbvaSavingsFund)
      )
    end
  end

  describe '.by_type' do
    it 'returns only products matching the given type' do
      expect(described_class.by_type('credit').to_a).to contain_exactly(
        an_instance_of(FinancialCatalogServices::Nu::NuCreditCard)
      )
    end

    it 'accepts the type constants' do
      expect(described_class.by_type(described_class::DEBIT).to_a).to contain_exactly(
        an_instance_of(FinancialCatalogServices::Klar::KlarDebitCard)
      )
    end

    it 'returns an empty collection when no product matches' do
      expect(described_class.by_type('nonexistent').to_a).to eq([])
    end
  end

  describe '.by_institution' do
    it 'returns only products from the given institution' do
      expect(described_class.by_institution('Nu').to_a).to contain_exactly(
        an_instance_of(FinancialCatalogServices::Nu::NuCreditCard)
      )
    end

    it 'returns an empty collection when no product matches' do
      expect(described_class.by_institution('Non Existent Bank').to_a).to eq([])
    end
  end

  describe 'chaining filters' do
    it 'combines by_type and by_institution' do
      expect(described_class.by_type('debit').by_institution('Klar').to_a).to contain_exactly(
        an_instance_of(FinancialCatalogServices::Klar::KlarDebitCard)
      )
    end

    it 'returns an empty collection when the combined filters match nothing' do
      expect(described_class.by_type('debit').by_institution('BBVA').to_a).to eq([])
    end

    it 'is order independent' do
      expect(described_class.by_institution('Klar').by_type('debit').to_a).to contain_exactly(
        an_instance_of(FinancialCatalogServices::Klar::KlarDebitCard)
      )
    end
  end

  describe FinancialCatalogServices::Registry::FilteredCollection do
    it 'is enumerable' do
      collection = described_class.new([FinancialCatalogServices::Nu::NuCreditCard.new])

      expect(collection.map(&:institution)).to eq(['Nu'])
    end
  end
end
