# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FinancialProduct, type: :model do
  subject(:product) { build(:financial_product) }

  describe 'asociaciones' do
    it { is_expected.to belong_to(:financial_institution) }
  end

  describe 'validaciones' do
    it { is_expected.to be_valid }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_length_of(:name).is_at_least(2).is_at_most(100) }
    it { is_expected.to validate_presence_of(:product_type) }
    it { is_expected.to validate_presence_of(:financial_institution) }

    context 'unicidad case-insensitive de nombre por institución' do
      let(:institution) { create(:financial_institution) }

      before { create(:financial_product, name: 'Nu Crédito', financial_institution: institution) }

      it 'rechaza nombre duplicado con misma capitalización en la misma institución' do
        duplicado = build(:financial_product, name: 'Nu Crédito', financial_institution: institution)
        expect(duplicado).not_to be_valid
        expect(duplicado.errors[:name]).to be_present
      end

      it 'rechaza nombre duplicado con distinta capitalización en la misma institución' do
        duplicado = build(:financial_product, name: 'nu crédito', financial_institution: institution)
        expect(duplicado).not_to be_valid
        expect(duplicado.errors[:name]).to be_present
      end

      it 'permite el mismo nombre en una institución diferente' do
        otra_institution = create(:financial_institution, name: 'BBVA')
        diferente = build(:financial_product, name: 'Nu Crédito', financial_institution: otra_institution)
        expect(diferente).to be_valid
      end

      it 'permite nombre diferente en la misma institución' do
        diferente = build(:financial_product, name: 'Nu Débito', financial_institution: institution)
        expect(diferente).to be_valid
      end
    end

    it 'rechaza nombre con menos de 2 caracteres' do
      product.name = 'A'
      expect(product).not_to be_valid
      expect(product.errors[:name]).to be_present
    end

    it 'rechaza nombre con más de 100 caracteres' do
      product.name = 'A' * 101
      expect(product).not_to be_valid
      expect(product.errors[:name]).to be_present
    end
  end

  describe 'enum product_type' do
    it { is_expected.to define_enum_for(:product_type).with_values(cash: 0, debit: 1, credit: 2, savings_fund: 3) }

    it 'acepta tipo cash' do
      product.product_type = :cash
      expect(product).to be_valid
    end

    it 'acepta tipo debit' do
      product.product_type = :debit
      expect(product).to be_valid
    end

    it 'acepta tipo credit' do
      product.product_type = :credit
      expect(product).to be_valid
    end

    it 'acepta tipo savings_fund' do
      product.product_type = :savings_fund
      expect(product).to be_valid
    end
  end

  describe 'callbacks' do
    it 'elimina espacios del nombre antes de validar' do
      product.name = '  Nu Débito  '
      product.valid?
      expect(product.name).to eq('Nu Débito')
    end
  end

  describe 'scopes' do
    let(:institution) { create(:financial_institution) }
    let!(:activo) { create(:financial_product, name: 'Activo', financial_institution: institution, active: true) }
    let!(:inactivo) { create(:financial_product, name: 'Inactivo', financial_institution: institution, active: false) }

    describe '.active' do
      it 'retorna solo productos activos' do
        expect(described_class.active).to include(activo)
        expect(described_class.active).not_to include(inactivo)
      end
    end

    describe '.inactive' do
      it 'retorna solo productos inactivos' do
        expect(described_class.inactive).to include(inactivo)
        expect(described_class.inactive).not_to include(activo)
      end
    end

    describe '.by_institution' do
      let(:otra) { create(:financial_institution, name: 'Otra') }
      let!(:otro_producto) { create(:financial_product, name: 'Otro', financial_institution: otra) }

      it 'retorna solo los productos de la institución indicada' do
        result = described_class.by_institution(institution.id)
        expect(result).to include(activo, inactivo)
        expect(result).not_to include(otro_producto)
      end
    end

    describe '.by_type' do
      let!(:credito) do
        create(:financial_product, name: 'Credito', financial_institution: institution, product_type: :credit)
      end

      it 'retorna solo los productos del tipo indicado' do
        result = described_class.by_type(:credit)
        expect(result).to include(credito)
        expect(result).not_to include(activo)
      end
    end

    describe '.alphabetical' do
      let!(:primero) { create(:financial_product, name: 'Albo Card', financial_institution: institution) }
      let!(:segundo) { create(:financial_product, name: 'Zinco Card', financial_institution: institution) }

      it 'ordena por nombre de forma case-insensitive' do
        nombres = described_class.alphabetical.pluck(:name)
        indice_albo = nombres.index('Albo Card')
        indice_zinco = nombres.index('Zinco Card')
        expect(indice_albo).to be < indice_zinco
      end
    end
  end
end
