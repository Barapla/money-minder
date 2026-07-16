# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FinancialNetworks::BaseLevel do
  it 'raises NotImplementedError for name' do
    expect { described_class.name }.to raise_error(NotImplementedError)
  end

  it 'defaults benefits to an empty array' do
    expect(described_class.benefits).to eq([])
  end

  it 'derives id from the real class name, not the overridden display name' do
    expect(FinancialNetworks::Visa::Gold.id).to eq('visa_gold')
  end

  it 'derives network_id from the enclosing network class' do
    expect(FinancialNetworks::Mastercard::WorldElite.network_id).to eq('mastercard')
    expect(FinancialNetworks::Mastercard::WorldElite.id).to eq('mastercard_world_elite')
  end
end
