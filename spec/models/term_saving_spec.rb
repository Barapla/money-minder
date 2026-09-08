# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TermSaving, type: :model do
  let(:user) { create(:user, first_name: 'Bryan') }
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
    TermSaving.new(default_attrs.merge(attrs))
  end

  def default_attrs
    {
      budget:,
      term_days: 90,
      rate_locked: 0.12,
      started_at: Date.current,
      principal_amount: 10_000
    }
  end

  describe 'matures_at (CA1)' do
    it 'se calcula automaticamente como started_at + term_days y status es active por defecto' do
      term_saving = build_term_saving(started_at: Date.new(2026, 1, 1), term_days: 90)

      expect(term_saving).to be_valid
      expect(term_saving.matures_at).to eq(Date.new(2026, 1, 1) + 90)
      expect(term_saving.status).to eq('active')
    end
  end

  describe 'validaciones de presencia' do
    it 'requiere term_days, rate_locked, started_at y principal_amount' do
      term_saving = TermSaving.new(budget:)

      expect(term_saving).to be_invalid
      expect(term_saving.errors[:term_days]).to be_present
      expect(term_saving.errors[:rate_locked]).to be_present
      expect(term_saving.errors[:started_at]).to be_present
      expect(term_saving.errors[:principal_amount]).to be_present
    end
  end

  describe 'inmutabilidad de rate_locked' do
    it 'permite fijar rate_locked al crear' do
      term_saving = build_term_saving(rate_locked: 0.15)

      expect(term_saving).to be_valid
    end

    it 'rechaza cambiar rate_locked despues de creado' do
      term_saving = build_term_saving.tap(&:save!)

      term_saving.rate_locked = 0.20
      expect(term_saving).to be_invalid
      expect(term_saving.errors[:rate_locked]).to include('no puede modificarse despues de creado')
    end

    it 'permite actualizar otros atributos sin tocar rate_locked' do
      term_saving = build_term_saving.tap(&:save!)

      term_saving.status = :matured
      expect(term_saving).to be_valid
    end
  end

  describe 'asociacion a un producto del catalogo (CA2)' do
    it 'autogenera el nombre con el prefijo Ahorro cuando no hay nombre manual' do
      term_saving = build_term_saving(financial_product_id: 'nu_frozen_savings90')

      expect(term_saving).to be_valid
      expect(term_saving.name).to eq('Ahorro Congelado 90 dias de Bryan')
    end
  end

  describe 'sincronizacion del nombre con el Budget contenedor (FEAT-027)' do
    it 'copia el nombre del ahorro al Budget cuando este todavia no tiene uno' do
      budget.update_column(:name, '')
      term_saving = build_term_saving(financial_product_id: 'nu_frozen_savings90')

      expect(term_saving).to be_valid
      expect(term_saving.budget.name).to eq('Ahorro Congelado 90 dias de Bryan')
      expect(Budget.find(budget.id).name).to eq('') # la sincronizacion es en memoria, no persiste el Budget solo
    end

    it 'no pisa un nombre de Budget ya existente' do
      term_saving = build_term_saving(financial_product_id: 'nu_frozen_savings90')

      expect(term_saving).to be_valid
      expect(term_saving.budget.name).to eq('Ahorro a Plazo')
    end
  end

  describe 'financial_product_id invalido' do
    it 'falla la validacion con un mensaje claro' do
      term_saving = build_term_saving(financial_product_id: 'no_existe')

      expect(term_saving).to be_invalid
      expect(term_saving.errors[:financial_product_id])
        .to include('no corresponde a ningun producto del catalogo financiero')
    end
  end

  describe '#mature!' do
    it 'transiciona a matured cuando matures_at ya paso' do
      term_saving = build_term_saving(started_at: 100.days.ago.to_date, term_days: 90).tap(&:save!)

      term_saving.mature!

      expect(term_saving.reload.status).to eq('matured')
    end

    it 'no transiciona si matures_at aun no llega' do
      term_saving = build_term_saving(started_at: Date.current, term_days: 90).tap(&:save!)

      term_saving.mature!

      expect(term_saving.reload.status).to eq('active')
    end
  end
end
