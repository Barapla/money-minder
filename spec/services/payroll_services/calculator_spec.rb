# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PayrollServices::Calculator, type: :service do
  let(:base_profile) { build(:payroll_profile, base_salary: 20_000, non_taxable_bonuses: {}) }

  subject(:calculator) { described_class.new(base_profile) }

  describe '#calculate_taxable_base' do
    it 'retorna el sueldo base como BigDecimal' do
      expect(calculator.calculate_taxable_base).to eq(BigDecimal('20000'))
    end
  end

  describe '#calculate_total_bonuses' do
    context 'sin bonos no gravados' do
      it 'retorna cero' do
        expect(calculator.calculate_total_bonuses).to eq(BigDecimal('0'))
      end
    end

    context 'con non_taxable_bonuses nil' do
      let(:base_profile) { build(:payroll_profile, base_salary: 20_000, non_taxable_bonuses: nil) }

      it 'retorna cero sin error' do
        expect(calculator.calculate_total_bonuses).to eq(BigDecimal('0'))
      end
    end

    context 'CA6: con múltiples bonos no gravados' do
      let(:base_profile) do
        build(:payroll_profile, base_salary: 20_000,
                                non_taxable_bonuses: { 'transporte' => 1000, 'teletrabajo' => 500, 'vales' => 500 })
      end

      it 'suma todos los bonos sin incluirlos en la base gravada' do
        expect(calculator.calculate_total_bonuses).to eq(BigDecimal('2000'))
      end
    end
  end

  describe '#calculate_savings_fund_employee_contribution' do
    context 'CA2: sueldo base $20,000 con bonos $2,000 y tasa 4%' do
      let(:base_profile) do
        build(:payroll_profile, base_salary: 20_000,
                                non_taxable_bonuses: { 'transporte' => 2000 },
                                savings_fund_rate: 4.0)
      end

      it 'aplica 4% únicamente sobre sueldo base ($800)' do
        expect(calculator.calculate_savings_fund_employee_contribution).to eq(BigDecimal('800'))
      end

      it 'no incluye bonos en la base del cálculo' do
        expect(calculator.calculate_savings_fund_employee_contribution).not_to eq(BigDecimal('880'))
      end
    end

    context 'CA5: sin tasa personalizada usa savings_fund_rate del perfil' do
      let(:base_profile) { build(:payroll_profile, base_salary: 20_000, savings_fund_rate: 4.0) }

      it 'aplica la tasa del perfil' do
        expect(calculator.calculate_savings_fund_employee_contribution).to eq(BigDecimal('800'))
      end
    end
  end

  describe '#calculate_savings_fund_employer_contribution' do
    it 'es igual a la aportación del trabajador' do
      expect(calculator.calculate_savings_fund_employer_contribution).to eq(
        calculator.calculate_savings_fund_employee_contribution
      )
    end
  end

  describe '#calculate_isr_estimated' do
    context 'CA3: con tasa personalizada 18.6%' do
      let(:base_profile) { build(:payroll_profile, base_salary: 20_000, custom_isr_rate: 18.6) }

      it 'aplica tasa personalizada sobre sueldo base ($3,720)' do
        expect(calculator.calculate_isr_estimated).to eq(BigDecimal('3720'))
      end
    end

    context 'CA5: sin tasa personalizada usa DEFAULT_ISR_RATE (18.6%)' do
      let(:base_profile) { build(:payroll_profile, base_salary: 20_000, custom_isr_rate: nil) }

      it 'aplica tasa default del 18.6%' do
        expect(calculator.calculate_isr_estimated).to eq(BigDecimal('3720'))
      end
    end
  end

  describe '#calculate_imss_estimated' do
    context 'CA3: con tasa personalizada 3%' do
      let(:base_profile) { build(:payroll_profile, base_salary: 20_000, custom_imss_rate: 3.0) }

      it 'aplica tasa personalizada sobre sueldo base ($600)' do
        expect(calculator.calculate_imss_estimated).to eq(BigDecimal('600'))
      end
    end

    context 'CA5: sin tasa personalizada usa DEFAULT_IMSS_RATE (3%)' do
      let(:base_profile) { build(:payroll_profile, base_salary: 20_000, custom_imss_rate: nil) }

      it 'aplica tasa default del 3%' do
        expect(calculator.calculate_imss_estimated).to eq(BigDecimal('600'))
      end
    end
  end

  describe '#calculate_net_salary' do
    context 'CA4: $20,000 base + $2,000 bonos con deducciones (ISR 18.6%, IMSS 3%, FA 4%)' do
      let(:base_profile) do
        build(:payroll_profile,
              base_salary: 20_000,
              non_taxable_bonuses: { 'transporte' => 2000 },
              savings_fund_rate: 4.0,
              custom_isr_rate: 18.6,
              custom_imss_rate: 3.0)
      end

      it 'calcula $16,880 = $20,000 + $2,000 - $800 - $3,720 - $600' do
        expect(calculator.calculate_net_salary).to eq(BigDecimal('16880'))
      end
    end

    context 'CA5: sin tasas personalizadas usa defaults' do
      let(:base_profile) do
        build(:payroll_profile,
              base_salary: 20_000,
              non_taxable_bonuses: {},
              savings_fund_rate: 4.0,
              custom_isr_rate: nil,
              custom_imss_rate: nil)
      end

      it 'aplica ISR 18.6% e IMSS 3% por defecto' do
        expected = BigDecimal('20000') - BigDecimal('800') - BigDecimal('3720') - BigDecimal('600')
        expect(calculator.calculate_net_salary).to eq(expected)
      end
    end

    context 'CA6: con múltiples bonos no gravados' do
      let(:base_profile) do
        build(:payroll_profile,
              base_salary: 20_000,
              non_taxable_bonuses: { 'transporte' => 1000, 'teletrabajo' => 500, 'vales' => 500 },
              savings_fund_rate: 4.0,
              custom_isr_rate: 18.6,
              custom_imss_rate: 3.0)
      end

      it 'suma todos los bonos al neto sin incluirlos en la base gravada' do
        expect(calculator.calculate_net_salary).to eq(BigDecimal('16880'))
      end
    end
  end

  describe '#call' do
    it 'retorna un resultado exitoso' do
      expect(calculator.call).to be_success
    end

    it 'incluye todos los campos del cálculo' do
      result = calculator.call
      expect(result.data.keys).to match_array(
        %i[base_salary total_bonuses savings_fund_employee savings_fund_employer
           isr_estimated imss_estimated net_salary]
      )
    end

    it 'los valores son BigDecimal' do
      result = calculator.call
      expect(result.data[:base_salary]).to be_a(BigDecimal)
      expect(result.data[:net_salary]).to be_a(BigDecimal)
    end
  end
end
