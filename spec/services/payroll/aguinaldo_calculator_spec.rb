# frozen_string_literal: true

require 'rails_helper'

# Articulo 87 LFT: prestacion ANUAL de minimo 15 dias, proporcional al tiempo
# trabajado dentro del año calendario que se paga.
RSpec.describe Payroll::AguinaldoCalculator, type: :service do
  let(:salary) { BigDecimal('30000') }       # $1,000 diarios (30000/30)
  let(:quince_dias) { BigDecimal('15000') }  # 15 dias completos

  def calcular(hire_date:, calculation_date:)
    described_class.new(monthly_gross_salary: salary, hire_date:, calculation_date:).call
  end

  describe 'año trabajado completo' do
    # La antiguedad NO multiplica: es la correccion al bug que daba 15 dias por
    # cada año acumulado (5 años => 75 dias).
    it 'da 15 días con dos años de antigüedad, no 30' do
      result = calcular(hire_date: Date.new(2024, 6, 23), calculation_date: Date.new(2026, 6, 23))

      expect(result).to be_success
      expect(result.data[:amount]).to eq(quince_dias)
      expect(result.data[:proportional]).to be(false)
    end

    it 'da 15 días con cinco años de antigüedad' do
      result = calcular(hire_date: Date.new(2021, 1, 10), calculation_date: Date.new(2026, 12, 20))

      expect(result.data[:amount]).to eq(quince_dias)
    end

    it 'da 15 días exactos aunque el año sea bisiesto' do
      result = calcular(hire_date: Date.new(2020, 3, 1), calculation_date: Date.new(2024, 12, 20))

      expect(result.data[:days_in_year]).to eq(366)
      expect(result.data[:amount]).to eq(quince_dias)
    end

    # Entró en un año anterior, así que trabajó los 365 días del año que se paga.
    it 'da el año completo a quien entró en un año previo' do
      result = calcular(hire_date: Date.new(2025, 11, 3), calculation_date: Date.new(2026, 12, 20))

      expect(result.data[:days_worked]).to eq(365)
      expect(result.data[:amount]).to eq(quince_dias)
    end
  end

  describe 'primer año incompleto' do
    it 'reparte proporcional al tiempo trabajado en el año' do
      result = calcular(hire_date: Date.new(2026, 7, 27), calculation_date: Date.new(2026, 12, 20))

      # 27-jul al 31-dic = 158 días
      expect(result.data[:days_worked]).to eq(158)
      expect(result.data[:proportional]).to be(true)
      expect(result.data[:amount]).to eq((BigDecimal('1000') * 15 * 158 / 365).round(2))
    end

    # El aguinaldo se paga antes del 20-dic pero cubre el año entero: la fecha
    # de calculo no recorta los dias que faltan del mes.
    it 'no recorta los días por calcularse antes de fin de año' do
      diciembre = calcular(hire_date: Date.new(2026, 7, 27), calculation_date: Date.new(2026, 12, 20))
      septiembre = calcular(hire_date: Date.new(2026, 7, 27), calculation_date: Date.new(2026, 9, 24))

      expect(septiembre.data[:amount]).to eq(diciembre.data[:amount])
    end

    it 'da el mínimo al que entró el último día del año' do
      result = calcular(hire_date: Date.new(2026, 12, 31), calculation_date: Date.new(2026, 12, 31))

      expect(result.data[:days_worked]).to eq(1)
      expect(result.data[:amount]).to eq((BigDecimal('1000') * 15 / 365).round(2))
    end
  end

  describe 'fechas inválidas' do
    it 'rechaza calcular antes de la fecha de ingreso' do
      result = calcular(hire_date: Date.new(2026, 6, 23), calculation_date: Date.new(2026, 1, 1))

      expect(result).to be_failure
      expect(result.error).to eq(:invalid_dates)
    end
  end
end
