# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FinancialNetworks::BaseNetwork do
  it 'raises NotImplementedError for name' do
    expect { described_class.name }.to raise_error(NotImplementedError)
  end

  it 'raises NotImplementedError for all_levels' do
    expect { described_class.all_levels }.to raise_error(NotImplementedError)
  end
end
