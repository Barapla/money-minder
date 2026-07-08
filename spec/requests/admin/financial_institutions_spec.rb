# frozen_string_literal: true

require 'rails_helper'

RSpec.describe '/admin/financial_institutions', type: :request do
  let(:admin_user) { create(:user, :admin) }
  let(:regular_user) { create(:user) }
  let!(:institution) { create(:financial_institution, name: 'BBVA', active: true) }

  let(:valid_params) { { financial_institution: { name: 'Nu', active: true } } }
  let(:invalid_params) { { financial_institution: { name: '', active: true } } }

  describe 'sin autenticacion' do
    it 'redirige al login en GET /admin/financial_institutions' do
      get admin_financial_institutions_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'redirige al login en POST /admin/financial_institutions' do
      post admin_financial_institutions_path, params: valid_params
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe 'como usuario sin rol admin (CA9)' do
    before { sign_in regular_user }

    it 'redirige al inicio en GET /admin/financial_institutions' do
      get admin_financial_institutions_path
      expect(response).to redirect_to(root_path)
    end

    it 'redirige al inicio en POST /admin/financial_institutions' do
      post admin_financial_institutions_path, params: valid_params
      expect(response).to redirect_to(root_path)
    end
  end

  describe 'como administrador' do
    before { sign_in admin_user }

    describe 'GET /admin/financial_institutions (CA1)' do
      it 'retorna respuesta exitosa' do
        get admin_financial_institutions_path
        expect(response).to have_http_status(:ok)
      end

      it 'muestra las instituciones con nombre y estado' do
        get admin_financial_institutions_path
        expect(response.body).to include('BBVA')
      end

      context 'con filtro de activas (CA8)' do
        let!(:inactiva) { create(:financial_institution, name: 'Klar', active: false) }

        it 'muestra solo instituciones activas cuando se filtra' do
          get admin_financial_institutions_path(active_only: 'true')
          expect(response.body).to include('BBVA')
          expect(response.body).not_to include('Klar')
        end

        it 'muestra todas las instituciones sin filtro' do
          get admin_financial_institutions_path
          expect(response.body).to include('BBVA')
          expect(response.body).to include('Klar')
        end
      end
    end

    describe 'GET /admin/financial_institutions/new (CA2)' do
      it 'retorna respuesta exitosa' do
        get new_admin_financial_institution_path
        expect(response).to have_http_status(:ok)
      end

      it 'muestra el formulario con campo de nombre' do
        get new_admin_financial_institution_path
        expect(response.body).to include('financial_institution[name]')
      end

      it 'muestra el campo activo/inactivo' do
        get new_admin_financial_institution_path
        expect(response.body).to include('financial_institution[active]')
      end
    end

    describe 'POST /admin/financial_institutions' do
      context 'con parametros validos (CA3)' do
        it 'crea la institucion y redirige al listado' do
          expect do
            post admin_financial_institutions_path, params: valid_params
          end.to change(FinancialInstitution, :count).by(1)

          expect(response).to redirect_to(admin_financial_institutions_path)
        end
      end

      context 'con nombre duplicado (CA4)' do
        it 'no crea la institucion y muestra error' do
          expect do
            post admin_financial_institutions_path,
                 params: { financial_institution: { name: 'BBVA', active: true } }
          end.not_to change(FinancialInstitution, :count)

          expect(response).to have_http_status(:unprocessable_entity)
        end
      end

      context 'sin nombre (CA5)' do
        it 'no crea la institucion y muestra error' do
          expect do
            post admin_financial_institutions_path, params: invalid_params
          end.not_to change(FinancialInstitution, :count)

          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end

    describe 'GET /admin/financial_institutions/:id/edit' do
      it 'retorna respuesta exitosa' do
        get edit_admin_financial_institution_path(institution)
        expect(response).to have_http_status(:ok)
      end
    end

    describe 'PATCH /admin/financial_institutions/:id (CA6)' do
      it 'actualiza la institucion y redirige' do
        patch admin_financial_institution_path(institution),
              params: { financial_institution: { name: 'BBVA Mexico', active: false } }

        expect(response).to redirect_to(admin_financial_institutions_path)
        institution.reload
        expect(institution.active).to be(false)
      end

      context 'con nombre invalido' do
        it 'no actualiza y retorna error' do
          patch admin_financial_institution_path(institution),
                params: { financial_institution: { name: '' } }

          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end

    describe 'DELETE /admin/financial_institutions/:id (CA7)' do
      it 'elimina la institucion y redirige' do
        expect do
          delete admin_financial_institution_path(institution)
        end.to change(FinancialInstitution, :count).by(-1)

        expect(response).to redirect_to(admin_financial_institutions_path)
      end
    end
  end
end
