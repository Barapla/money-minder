# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FinancialNetworks::Visa do
  it { expect(described_class).to be < FinancialNetworks::BaseNetwork }
  it { expect(described_class.id).to eq('visa') }
  it { expect(described_class.name).to eq('Visa') }

  it 'returns the 5 Visa levels' do
    expect(described_class.all_levels).to eq(
      [
        FinancialNetworks::Visa::Classic,
        FinancialNetworks::Visa::Gold,
        FinancialNetworks::Visa::Platinum,
        FinancialNetworks::Visa::Signature,
        FinancialNetworks::Visa::Infinite
      ]
    )
  end

  it 'gives every level a benefits array with at least 2 entries' do
    described_class.all_levels.each do |level|
      expect(level.benefits.size).to be >= 2
    end
  end

  it 'exposes shared Visa Gold benefits regardless of issuer' do
    expect(FinancialNetworks::Visa::Gold.benefits).to include('Proteccion de compras hasta 90 dias')
  end
end
