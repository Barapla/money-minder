# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ChatbotServices::HorizonParser, type: :service do
  it 'saca el día exacto cuando el mensaje lo dice' do
    expect(described_class.call('hasta el dia 25 de diciembre de 2026')).to eq(Date.new(2026, 12, 25))
  end

  it 'usa fin de mes cuando solo se menciona el mes' do
    expect(described_class.call('para marzo de 2027')).to eq(Date.new(2027, 3, 31))
  end

  it 'usa fin de año cuando solo se menciona el año' do
    expect(described_class.call('para 2027')).to eq(Date.new(2027, 12, 31))
  end

  it 'devuelve nil cuando no hay fecha en el mensaje' do
    expect(described_class.call('cuanto tengo disponible')).to be_nil
  end

  it 'cae al horizonte por defecto de 6 meses' do
    expect(described_class.new('cuanto tengo').call_or_default).to eq(6.months.from_now.to_date)
  end

  it 'ignora un día imposible y usa fin de mes' do
    expect(described_class.call('el 45 de febrero de 2027')).to eq(Date.new(2027, 2, 28))
  end
end
