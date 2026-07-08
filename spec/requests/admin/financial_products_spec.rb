# frozen_string_literal: true

require 'rails_helper'

RSpec.describe '/admin/financial_products', type: :request do
  let(:admin_user) { create(:user, :admin) }
  let(:regular_user) { create(:user) }
  let!(:institution) { create(:financial_institution, name: 'Nu') }
  let!(:product) do
    create(:financial_product, name: 'Nu Débito', financial_institution: institution, product_type: :debit)
  end

  let(:valid_params) do
    { financial_product: { name: 'Nu Crédito', product_type: 'credit',
                           financial_institution_id: institution.id, active: true } }
  end

  let(:invalid_params) do
    { financial_product: { name: '', product_type: 'debit', financial_institution_id: institution.id, active: true } }
  end

  describe 'sin autenticacion' do
    it 'redirige al login en GET /admin/financial_products' do
      get admin_financial_products_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'redirige al login en POST /admin/financial_products' do
      post admin_financial_products_path, params: valid_params
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe 'como usuario sin rol admin (CA9)' do
    before { sign_in regular_user }

    it 'redirige al inicio en GET /admin/financial_products' do
      get admin_financial_products_path
      expect(response).to redirect_to(root_path)
    end

    it 'redirige al inicio en GET /admin/financial_products/new' do
      get new_admin_financial_product_path
      expect(response).to redirect_to(root_path)
    end

    it 'redirige al inicio en POST /admin/financial_products' do
      post admin_financial_products_path, params: valid_params
      expect(response).to redirect_to(root_path)
    end

    it 'redirige al inicio en GET /admin/financial_products/:id/edit' do
      get edit_admin_financial_product_path(product)
      expect(response).to redirect_to(root_path)
    end

    it 'redirige al inicio en PATCH /admin/financial_products/:id' do
      patch admin_financial_product_path(product), params: valid_params
      expect(response).to redirect_to(root_path)
    end
  end

  describe 'como administrador' do
    before { sign_in admin_user }

    describe 'GET /admin/financial_products (CA1)' do
      it 'retorna respuesta exitosa' do
        get admin_financial_products_path
        expect(response).to have_http_status(:ok)
      end

      it 'muestra los productos con nombre e institución' do
        get admin_financial_products_path
        expect(response.body).to include('Nu Débito')
      end

      it 'muestra la institución agrupadora (CA10)' do
        get admin_financial_products_path
        expect(response.body).to include('Nu')
      end

      context 'con filtro de activos (CA4)' do
        let!(:inactivo) do
          create(:financial_product, name: 'Producto Inactivo', financial_institution: institution, active: false)
        end

        it 'muestra solo productos activos cuando se filtra' do
          get admin_financial_products_path(active_only: 'true')
          expect(response.body).to include('Nu Débito')
          expect(response.body).not_to include('Producto Inactivo')
        end

        it 'muestra todos los productos sin filtro' do
          get admin_financial_products_path
          expect(response.body).to include('Nu Débito')
          expect(response.body).to include('Producto Inactivo')
        end
      end
    end

    describe 'GET /admin/financial_products/new (CA2)' do
      it 'retorna respuesta exitosa' do
        get new_admin_financial_product_path
        expect(response).to have_http_status(:ok)
      end

      it 'muestra el formulario con campo de nombre' do
        get new_admin_financial_product_path
        expect(response.body).to include('financial_product[name]')
      end

      it 'muestra el selector de institución' do
        get new_admin_financial_product_path
        expect(response.body).to include('financial_product[financial_institution_id]')
      end

      it 'muestra el selector de tipo de producto (CA5)' do
        get new_admin_financial_product_path
        expect(response.body).to include('financial_product[product_type]')
      end
    end

    describe 'POST /admin/financial_products' do
      context 'con parametros validos (CA2)' do
        it 'crea el producto y redirige al listado' do
          expect do
            post admin_financial_products_path, params: valid_params
          end.to change(FinancialProduct, :count).by(1)

          expect(response).to redirect_to(admin_financial_products_path)
        end

        it 'muestra mensaje de exito tras crear' do
          post admin_financial_products_path, params: valid_params
          follow_redirect!
          expect(response.body).to include('exitosamente')
        end
      end

      context 'con nombre vacio (CA6)' do
        it 'no crea el producto y retorna error' do
          expect do
            post admin_financial_products_path, params: invalid_params
          end.not_to change(FinancialProduct, :count)

          expect(response).to have_http_status(:unprocessable_entity)
        end
      end

      context 'con nombre duplicado en misma institución (CA6)' do
        it 'no crea el producto y retorna error de validacion' do
          expect do
            post admin_financial_products_path,
                 params: { financial_product: { name: 'Nu Débito', product_type: 'debit',
                                                financial_institution_id: institution.id, active: true } }
          end.not_to change(FinancialProduct, :count)

          expect(response).to have_http_status(:unprocessable_entity)
        end
      end

      context 'con nombre duplicado case-insensitive (CA6)' do
        it 'no crea el producto y retorna error' do
          expect do
            post admin_financial_products_path,
                 params: { financial_product: { name: 'nu débito', product_type: 'debit',
                                                financial_institution_id: institution.id, active: true } }
          end.not_to change(FinancialProduct, :count)

          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end

    describe 'GET /admin/financial_products/:id/edit (CA3)' do
      it 'retorna respuesta exitosa' do
        get edit_admin_financial_product_path(product)
        expect(response).to have_http_status(:ok)
      end

      it 'muestra el nombre del producto en el formulario' do
        get edit_admin_financial_product_path(product)
        expect(response.body).to include('Nu Débito')
      end
    end

    describe 'PATCH /admin/financial_products/:id (CA3, CA4)' do
      it 'actualiza el producto y redirige' do
        patch admin_financial_product_path(product),
              params: { financial_product: { name: 'Nu Débito Plus', product_type: 'debit',
                                             financial_institution_id: institution.id, active: true } }

        expect(response).to redirect_to(admin_financial_products_path)
        product.reload
        expect(product.name).to eq('Nu Débito Plus')
      end

      it 'puede marcar el producto como inactivo (CA4)' do
        patch admin_financial_product_path(product),
              params: { financial_product: { name: 'Nu Débito', product_type: 'debit',
                                             financial_institution_id: institution.id, active: false } }

        expect(response).to redirect_to(admin_financial_products_path)
        product.reload
        expect(product.active).to be(false)
      end

      context 'con parametros invalidos' do
        it 'no actualiza y retorna error' do
          patch admin_financial_product_path(product),
                params: { financial_product: { name: '', product_type: 'debit',
                                               financial_institution_id: institution.id } }

          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end
  end
end
