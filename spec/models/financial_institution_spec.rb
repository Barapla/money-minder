# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FinancialInstitution, type: :model do
  subject(:institution) { build(:financial_institution) }

  describe 'validaciones' do
    it { is_expected.to be_valid }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_length_of(:name).is_at_least(2) }

    context 'unicidad case-insensitive de name' do
      before { create(:financial_institution, name: 'BBVA') }

      it 'rechaza nombre duplicado con misma capitalización' do
        duplicado = build(:financial_institution, name: 'BBVA')
        expect(duplicado).not_to be_valid
        expect(duplicado.errors[:name]).to be_present
      end

      it 'rechaza nombre duplicado con distinta capitalización' do
        duplicado = build(:financial_institution, name: 'bbva')
        expect(duplicado).not_to be_valid
        expect(duplicado.errors[:name]).to be_present
      end

      it 'rechaza nombre duplicado con capitalización mixta' do
        duplicado = build(:financial_institution, name: 'BbVa')
        expect(duplicado).not_to be_valid
        expect(duplicado.errors[:name]).to be_present
      end

      it 'acepta nombre diferente' do
        diferente = build(:financial_institution, name: 'Nu')
        expect(diferente).to be_valid
      end
    end

    it 'rechaza name con menos de 2 caracteres' do
      institution.name = 'A'
      expect(institution).not_to be_valid
      expect(institution.errors[:name]).to be_present
    end
  end

  describe 'callbacks' do
    it 'elimina espacios del nombre antes de validar' do
      institution.name = '  Nu  '
      institution.valid?
      expect(institution.name).to eq('Nu')
    end

    it 'genera code desde el nombre si está vacío' do
      institution.name = 'BBVA Bancomer'
      institution.valid?
      expect(institution.code).to eq('bbva-bancomer')
    end

    it 'no sobreescribe code si ya tiene valor' do
      institution.name = 'Nu'
      institution.code = 'nu-banco'
      institution.valid?
      expect(institution.code).to eq('nu-banco')
    end
  end

  describe 'scopes' do
    let!(:activa) { create(:financial_institution, name: 'Nu', active: true) }
    let!(:inactiva) { create(:financial_institution, name: 'Klar', active: false) }

    describe '.active' do
      it 'retorna solo instituciones activas' do
        expect(described_class.active).to include(activa)
        expect(described_class.active).not_to include(inactiva)
      end
    end

    describe '.inactive' do
      it 'retorna solo instituciones inactivas' do
        expect(described_class.inactive).to include(inactiva)
        expect(described_class.inactive).not_to include(activa)
      end
    end

    describe '.alphabetical' do
      let!(:primero) { create(:financial_institution, name: 'Albo') }
      let!(:segundo) { create(:financial_institution, name: 'Zinco') }

      it 'ordena por nombre de forma case-insensitive' do
        nombres = described_class.alphabetical.pluck(:name)
        indice_albo = nombres.index('Albo')
        indice_zinco = nombres.index('Zinco')
        expect(indice_albo).to be < indice_zinco
      end
    end
  end
end
