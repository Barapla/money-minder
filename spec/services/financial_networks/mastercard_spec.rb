# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FinancialNetworks::Mastercard do
  it { expect(described_class).to be < FinancialNetworks::BaseNetwork }
  it { expect(described_class.id).to eq('mastercard') }
  it { expect(described_class.name).to eq('Mastercard') }

  it 'returns the 5 Mastercard levels' do
    expect(described_class.all_levels).to eq(
      [
        FinancialNetworks::Mastercard::Standard,
        FinancialNetworks::Mastercard::Gold,
        FinancialNetworks::Mastercard::Platinum,
        FinancialNetworks::Mastercard::World,
        FinancialNetworks::Mastercard::WorldElite
      ]
    )
  end

  it 'exposes World benefits with level-specific redemption limits' do
    expect(FinancialNetworks::Mastercard::World.id).to eq('mastercard_world')
    expect(FinancialNetworks::Mastercard::World.benefits).to be_an(Array)
  end
end
