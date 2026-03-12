# spec/models/group_catalog_spec.rb
require 'rails_helper'

RSpec.describe GroupCatalog, type: :model do
  # ==================== ASSOCIATIONS ====================
  describe 'associations' do
    it { should have_many(:catalogs).dependent(:destroy) }
    it { should have_many(:statuses).dependent(:destroy) }
  end

  # ==================== VALIDATIONS ====================
  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:code) }
    it { should validate_uniqueness_of(:code) }
  end

  describe 'CRUD operations' do
    describe '#create' do
      context 'with valid attributes' do
        it 'creates a new group catalog' do
          # create: construye Y guarda
          expect {
            create(:group_catalog)
          }.to change(GroupCatalog, :count).by(1)
        end

        it 'sets active to true by default' do
          group = create(:group_catalog)
          expect(group.active).to be true
        end

        it 'generates a uuid' do
          group = create(:group_catalog)
          group.reload
          expect(group.uuid).to be_present
          expect(group.uuid).to match(/^[a-f0-9\-]{36}$/i)
        end
        
        it 'creates with specific attributes' do
          # Puedes override cualquier atributo
          group = create(:group_catalog, 
            name: 'Custom Name',
            code: 'CUSTOM_CODE'
          )
          expect(group.name).to eq('Custom Name')
          expect(group.code).to eq('CUSTOM_CODE')
        end
        
        it 'creates using traits' do
          # Usando traits predefinidos
          group = create(:group_catalog, :account_types)
          expect(group.name).to eq('Account Types')
          expect(group.code).to eq('ACCOUNT_TYPES')
        end
      end

      context 'with invalid attributes' do
        it 'fails without name' do
          # build: objeto en memoria (para probar validaciones)
          group = build(:group_catalog, name: nil)
          expect(group).not_to be_valid
          expect(group.errors[:name]).to include("no puede estar vacío")
        end

        it 'fails without code' do
          group = build(:group_catalog, code: nil)
          expect(group).not_to be_valid
          expect(group.errors[:code]).to include("no puede estar vacío")
        end

        it 'fails with duplicate code' do
          # Primero crea uno
          create(:group_catalog, code: 'DUPLICATE')
          
          # Luego intenta crear otro con el mismo código
          duplicate = build(:group_catalog, code: 'DUPLICATE')
          
          expect(duplicate).not_to be_valid
          expect(duplicate.errors[:code]).to include("has already been taken")
        end
      end
    end

    describe '#update' do
      # let: crea cuando se usa por primera vez (lazy)
      let(:group_catalog) { create(:group_catalog) }

      it 'updates name successfully' do
        expect {
          group_catalog.update(name: 'Updated Name')
        }.to change { group_catalog.reload.name }.to('Updated Name')
      end

      it 'can be deactivated' do
        expect {
          group_catalog.update(active: false)
        }.to change { group_catalog.reload.active }.to(false)
      end

      it 'cannot update to duplicate code' do
        create(:group_catalog, code: 'EXISTING')
        group_catalog.code = 'EXISTING'
        
        expect(group_catalog).not_to be_valid
      end
    end

    describe '#destroy' do
      # let!: crea inmediatamente
      let!(:group_catalog) { create(:group_catalog) }

      it 'deletes the group catalog' do
        expect {
          group_catalog.destroy
        }.to change(GroupCatalog, :count).by(-1)
      end

      context 'with associated catalogs' do
        let!(:catalog) { create(:catalog, group_catalog: group_catalog) }

        it 'deletes associated catalogs' do
          expect {
            group_catalog.destroy
          }.to change(Catalog, :count).by(-1)
        end
      end

      context 'with associated statuses' do
        let!(:status) { create(:status, group_catalog: group_catalog) }

        it 'deletes associated statuses' do
          expect {
            group_catalog.destroy
          }.to change(Status, :count).by(-1)
        end
      end
    end
  end

  # ==================== INSTANCE METHODS ====================
  describe 'instance methods' do
    describe '#to_s' do
      let(:group_catalog) { create(:group_catalog, name: 'Account Types') }

      it 'returns the name' do
        expect(group_catalog.to_s).to eq('Account Types')
      end
    end
  end
end