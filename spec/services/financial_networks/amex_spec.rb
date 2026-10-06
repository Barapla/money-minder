# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FinancialNetworks::Amex do
  it { expect(described_class).to be < FinancialNetworks::BaseNetwork }
  it { expect(described_class.id).to eq('amex') }

  it 'returns the 4 Amex levels' do
    expect(described_class.all_levels).to eq(
      [
        FinancialNetworks::Amex::Green,
        FinancialNetworks::Amex::Gold,
        FinancialNetworks::Amex::Platinum,
        FinancialNetworks::Amex::Centurion
      ]
    )
  end

  it 'has Amex Platinum benefits independent of bank-specific benefits' do
    expect(FinancialNetworks::Amex::Platinum.benefits).to include('Acceso ilimitado a Centurion Lounge')
  end

  it 'has Amex Gold benefits distinct from Visa::Gold and Mastercard::Gold' do
    amex_benefits = FinancialNetworks::Amex::Gold.benefits
    expect(amex_benefits).not_to eq(FinancialNetworks::Visa::Gold.benefits)
    expect(amex_benefits).not_to eq(FinancialNetworks::Mastercard::Gold.benefits)
  end
end
