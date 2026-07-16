# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TermSavingServices::AccruedInterestCalculator, type: :service do
  let(:user) { create(:user) }
  let(:budget) do
    Budget.create!(
      name: 'Ahorro a Plazo',
      user:,
      budget_type: create(:catalog),
      color: create(:catalog),
      icon: create(:catalog),
      current_amount: 0
    )
  end

  def build_term_saving(attrs = {})
    TermSaving.create!(
      {
        budget:,
        term_days: 90,
        rate_locked: 0.12,
        started_at: Date.current,
        principal_amount: 10_000
      }.merge(attrs)
    )
  end

  describe 'devengo diario (CA3, producto con ACCRUAL_FREQUENCY = :daily)' do
    it 'calcula interes compuesto diario segun A = P * ((1 + r/365) ** dias - 1)' do
      term_saving = build_term_saving(financial_product_id: 'nu_frozen_savings90')

      accrued = described_class.call(term_saving, reference_date: Date.current + 30)

      expect(accrued).to eq((10_000 * (((1 + (0.12 / 365))**30) - 1)).round(2))
    end
  end

  describe 'devengo al vencimiento (CA4, producto con ACCRUAL_FREQUENCY = :at_maturity)' do
    it 'retorna $0 antes del vencimiento' do
      term_saving = build_term_saving(financial_product_id: 'bbva_savings_fund', term_days: 90)

      accrued = described_class.call(term_saving, reference_date: Date.current + 45)

      expect(accrued).to eq(0.0)
    end

    it 'liquida interes simple al llegar el vencimiento' do
      term_saving = build_term_saving(financial_product_id: 'bbva_savings_fund', term_days: 90)

      accrued = described_class.call(term_saving, reference_date: Date.current + 90)

      expect(accrued).to eq((10_000 * 0.12 * (90 / 365.0)).round(2))
    end
  end

  describe 'sin financial_product_id (CA7)' do
    it 'usa :at_maturity por defecto con interes simple' do
      term_saving = build_term_saving(term_days: 90)

      before_maturity = described_class.call(term_saving, reference_date: Date.current + 45)
      at_maturity = described_class.call(term_saving, reference_date: Date.current + 90)

      expect(before_maturity).to eq(0.0)
      expect(at_maturity).to eq((10_000 * 0.12 * (90 / 365.0)).round(2))
    end
  end

  describe 'rate_locked congelada (CA8)' do
    it 'usa rate_locked del TermSaving y no la tasa vigente del catalogo' do
      term_saving = build_term_saving(financial_product_id: 'nu_frozen_savings90', rate_locked: 0.20)

      accrued = described_class.call(term_saving, reference_date: Date.current + 30)

      expect(accrued).to eq((10_000 * (((1 + (0.20 / 365))**30) - 1)).round(2))
      expect(accrued).not_to eq((10_000 * (((1 + (0.12 / 365))**30) - 1)).round(2))
    end
  end

  describe 'antes de iniciar el plazo' do
    it 'no devenga intereses' do
      term_saving = build_term_saving(started_at: Date.current)

      accrued = described_class.call(term_saving, reference_date: Date.current)

      expect(accrued).to eq(0.0)
    end

    it 'no devenga intereses si reference_date es anterior a started_at' do
      term_saving = build_term_saving(started_at: Date.current)

      accrued = described_class.call(term_saving, reference_date: Date.current - 5)

      expect(accrued).to eq(0.0)
    end
  end
end
