# frozen_string_literal: true

require 'rails_helper'

RSpec.describe '/admin/financial_products/:financial_product_id/benefits', type: :request do
  let(:admin_user) { create(:user, :admin) }
  let(:regular_user) { create(:user) }
  let!(:institution) { create(:financial_institution, name: 'Nu') }
  let!(:product) do
    create(:financial_product, name: 'Cajita Turbo', financial_institution: institution,
                               product_type: :savings_fund)
  end
  let!(:benefit) do
    create(:financial_product_benefit, financial_product: product,
                                       benefit_type: :annual_yield, base_value: 13.0, unit: :percentage)
  end

  let(:valid_params) do
    {
      financial_product_benefit: {
        benefit_type: 'cashback',
        base_value: '2.0',
        unit: 'percentage',
        description: 'Cashback en compras',
        active: true
      }
    }
  end

  let(:invalid_params) do
    {
      financial_product_benefit: {
        benefit_type: '',
        base_value: '',
        unit: 'percentage'
      }
    }
  end

  describe 'sin autenticacion' do
    it 'redirige al login en GET /admin/financial_products/:id/benefits' do
      get admin_financial_product_benefits_path(product)
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'redirige al login en GET /admin/financial_products/:id/benefits/new' do
      get new_admin_financial_product_benefit_path(product)
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'redirige al login en POST /admin/financial_products/:id/benefits' do
      post admin_financial_product_benefits_path(product), params: valid_params
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe 'como usuario sin rol admin' do
    before { sign_in regular_user }

    it 'redirige al inicio en GET /admin/financial_products/:id/benefits' do
      get admin_financial_product_benefits_path(product)
      expect(response).to redirect_to(root_path)
    end

    it 'redirige al inicio en GET /admin/financial_products/:id/benefits/new' do
      get new_admin_financial_product_benefit_path(product)
      expect(response).to redirect_to(root_path)
    end

    it 'redirige al inicio en POST /admin/financial_products/:id/benefits' do
      post admin_financial_product_benefits_path(product), params: valid_params
      expect(response).to redirect_to(root_path)
    end

    it 'redirige al inicio en GET edit de benefit' do
      get edit_admin_financial_product_benefit_path(product, benefit)
      expect(response).to redirect_to(root_path)
    end

    it 'redirige al inicio en DELETE de benefit' do
      delete admin_financial_product_benefit_path(product, benefit)
      expect(response).to redirect_to(root_path)
    end
  end

  describe 'como administrador' do
    before { sign_in admin_user }

    describe 'GET /admin/financial_products/:id/benefits (CA1, CA7)' do
      it 'redirige al show del producto' do
        get admin_financial_product_benefits_path(product)
        expect(response).to redirect_to(admin_financial_product_path(product))
      end

      it 'muestra los beneficios en el show del producto tras redireccion' do
        get admin_financial_product_benefits_path(product)
        follow_redirect!
        expect(response.body).to include('Beneficios').or include('benefit')
      end
    end

    describe 'GET /admin/financial_products/:id/benefits/new (CA2, CA3, CA5, CA6)' do
      it 'retorna respuesta exitosa' do
        get new_admin_financial_product_benefit_path(product)
        expect(response).to have_http_status(:ok)
      end

      it 'muestra el formulario con selector de tipo de beneficio (CA2)' do
        get new_admin_financial_product_benefit_path(product)
        expect(response.body).to include('financial_product_benefit[benefit_type]')
      end

      it 'muestra el campo de valor base (CA3)' do
        get new_admin_financial_product_benefit_path(product)
        expect(response.body).to include('financial_product_benefit[base_value]')
      end

      it 'muestra el campo de valor reducido opcional (CA3)' do
        get new_admin_financial_product_benefit_path(product)
        expect(response.body).to include('financial_product_benefit[reduced_value]')
      end

      it 'muestra el campo de monto tope (CA5)' do
        get new_admin_financial_product_benefit_path(product)
        expect(response.body).to include('financial_product_benefit[amount_cap]')
      end

      it 'muestra el selector de unidad (CA6)' do
        get new_admin_financial_product_benefit_path(product)
        expect(response.body).to include('financial_product_benefit[unit]')
      end
    end

    describe 'POST /admin/financial_products/:id/benefits' do
      context 'con parametros validos (CA2)' do
        it 'crea el beneficio y redirige al producto' do
          expect do
            post admin_financial_product_benefits_path(product), params: valid_params
          end.to change(FinancialProductBenefit, :count).by(1)

          expect(response).to redirect_to(admin_financial_product_path(product))
        end

        it 'muestra mensaje de exito tras crear' do
          post admin_financial_product_benefits_path(product), params: valid_params
          follow_redirect!
          expect(response.body).to include('exitosamente')
        end

        it 'permite crear beneficio con reduced_value (CA3)' do
          post admin_financial_product_benefits_path(product), params: {
            financial_product_benefit: {
              benefit_type: 'annual_yield', base_value: '13.0',
              reduced_value: '7.0', unit: 'percentage', active: true
            }
          }
          expect(response).to redirect_to(admin_financial_product_path(product))
          created = FinancialProductBenefit.order(:created_at).last
          expect(created.reduced_value).to eq(7.0)
        end

        it 'permite crear beneficio con amount_cap (CA5)' do
          post admin_financial_product_benefits_path(product), params: {
            financial_product_benefit: {
              benefit_type: 'annual_yield', base_value: '15.0',
              amount_cap: '25000.0', unit: 'percentage', active: true
            }
          }
          expect(response).to redirect_to(admin_financial_product_path(product))
          created = FinancialProductBenefit.order(:created_at).last
          expect(created.amount_cap).to eq(25_000.0)
        end
      end

      context 'con parametros invalidos' do
        it 'no crea el beneficio y retorna error' do
          expect do
            post admin_financial_product_benefits_path(product), params: invalid_params
          end.not_to change(FinancialProductBenefit, :count)

          expect(response).to have_http_status(:unprocessable_entity)
        end

        it 'rechaza base_value mayor a 100 para porcentaje (CA4)' do
          expect do
            post admin_financial_product_benefits_path(product), params: {
              financial_product_benefit: {
                benefit_type: 'annual_yield', base_value: '150.0', unit: 'percentage', active: true
              }
            }
          end.not_to change(FinancialProductBenefit, :count)

          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end

    describe 'GET /admin/financial_products/:id/benefits/:id/edit (CA8)' do
      it 'retorna respuesta exitosa' do
        get edit_admin_financial_product_benefit_path(product, benefit)
        expect(response).to have_http_status(:ok)
      end

      it 'precarga los valores del beneficio en el formulario' do
        get edit_admin_financial_product_benefit_path(product, benefit)
        expect(response.body).to include('13')
      end
    end

    describe 'PATCH /admin/financial_products/:id/benefits/:id (CA8)' do
      it 'actualiza el beneficio y redirige al producto' do
        patch admin_financial_product_benefit_path(product, benefit), params: {
          financial_product_benefit: {
            benefit_type: 'annual_yield', base_value: '14.0', unit: 'percentage', active: true
          }
        }
        expect(response).to redirect_to(admin_financial_product_path(product))
        benefit.reload
        expect(benefit.base_value).to eq(14.0)
      end

      it 'muestra mensaje de exito tras actualizar (CA8)' do
        patch admin_financial_product_benefit_path(product, benefit), params: {
          financial_product_benefit: {
            benefit_type: 'annual_yield', base_value: '14.0', unit: 'percentage', active: true
          }
        }
        follow_redirect!
        expect(response.body).to include('exitosamente')
      end

      context 'con parametros invalidos' do
        it 'no actualiza y retorna error' do
          patch admin_financial_product_benefit_path(product, benefit), params: {
            financial_product_benefit: {
              benefit_type: 'annual_yield', base_value: '0', unit: 'percentage', active: true
            }
          }
          expect(response).to have_http_status(:unprocessable_entity)
          benefit.reload
          expect(benefit.base_value).to eq(13.0)
        end
      end
    end

    describe 'DELETE /admin/financial_products/:id/benefits/:id (CA8)' do
      it 'elimina el beneficio y redirige al producto' do
        expect do
          delete admin_financial_product_benefit_path(product, benefit)
        end.to change(FinancialProductBenefit, :count).by(-1)

        expect(response).to redirect_to(admin_financial_product_path(product))
      end

      it 'muestra mensaje de exito tras eliminar (CA8)' do
        delete admin_financial_product_benefit_path(product, benefit)
        follow_redirect!
        expect(response.body).to include('exitosamente')
      end
    end
  end
end
