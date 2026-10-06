# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FinancialNetworks do
  describe '.all_networks' do
    it 'returns Visa, Mastercard and Amex' do
      expect(described_class.all_networks).to eq(
        [FinancialNetworks::Visa, FinancialNetworks::Mastercard, FinancialNetworks::Amex]
      )
    end
  end

  describe '.find_level' do
    it 'finds a level by its stable id' do
      expect(described_class.find_level('visa_gold')).to eq(FinancialNetworks::Visa::Gold)
      expect(described_class.find_level('mastercard_world_elite')).to eq(FinancialNetworks::Mastercard::WorldElite)
    end

    it 'returns nil for an unknown id' do
      expect(described_class.find_level('discover_black')).to be_nil
    end
  end
end
