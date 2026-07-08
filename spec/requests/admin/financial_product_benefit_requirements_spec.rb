# frozen_string_literal: true

require 'rails_helper'

RSpec.describe '/admin/financial_products/:fp_id/benefits/:benefit_id/requirements', type: :request do
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
  let!(:requirement) do
    create(:financial_product_benefit_requirement, :min_transactions, benefit:)
  end

  let(:valid_params_min_transactions) do
    {
      financial_product_benefit_requirement: {
        requirement_type: 'min_transactions',
        min_transactions_count: '3',
        active: true
      }
    }
  end

  let(:valid_params_with_amount) do
    {
      financial_product_benefit_requirement: {
        requirement_type: 'min_transactions_with_amount',
        min_transactions_count: '4',
        min_amount_per_transaction: '50.00',
        active: true
      }
    }
  end

  let(:valid_params_accumulated) do
    {
      financial_product_benefit_requirement: {
        requirement_type: 'accumulated_amount',
        min_accumulated_amount: '2500.00',
        active: true
      }
    }
  end

  let(:valid_params_monthly_fee) do
    {
      financial_product_benefit_requirement: {
        requirement_type: 'monthly_fee',
        monthly_fee_amount: '179.00',
        active: true
      }
    }
  end

  let(:invalid_params) do
    {
      financial_product_benefit_requirement: {
        requirement_type: 'min_transactions',
        min_transactions_count: ''
      }
    }
  end

  describe 'sin autenticacion' do
    it 'redirige al login en GET new' do
      get new_admin_financial_product_benefit_requirement_path(product, benefit)
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'redirige al login en POST create' do
      post admin_financial_product_benefit_requirements_path(product, benefit),
           params: valid_params_min_transactions
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'redirige al login en GET edit' do
      get edit_admin_financial_product_benefit_requirement_path(product, benefit, requirement)
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'redirige al login en PATCH update' do
      patch admin_financial_product_benefit_requirement_path(product, benefit, requirement),
            params: valid_params_min_transactions
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'redirige al login en DELETE destroy' do
      delete admin_financial_product_benefit_requirement_path(product, benefit, requirement)
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe 'como usuario sin rol admin' do
    before { sign_in regular_user }

    it 'redirige al inicio en GET new' do
      get new_admin_financial_product_benefit_requirement_path(product, benefit)
      expect(response).to redirect_to(root_path)
    end

    it 'redirige al inicio en POST create' do
      post admin_financial_product_benefit_requirements_path(product, benefit),
           params: valid_params_min_transactions
      expect(response).to redirect_to(root_path)
    end

    it 'redirige al inicio en GET edit' do
      get edit_admin_financial_product_benefit_requirement_path(product, benefit, requirement)
      expect(response).to redirect_to(root_path)
    end

    it 'redirige al inicio en PATCH update' do
      patch admin_financial_product_benefit_requirement_path(product, benefit, requirement),
            params: valid_params_min_transactions
      expect(response).to redirect_to(root_path)
    end

    it 'redirige al inicio en DELETE destroy' do
      delete admin_financial_product_benefit_requirement_path(product, benefit, requirement)
      expect(response).to redirect_to(root_path)
    end
  end

  describe 'como administrador' do
    before { sign_in admin_user }

    describe 'GET new (CA2-CA5)' do
      it 'responde 200' do
        get new_admin_financial_product_benefit_requirement_path(product, benefit)
        expect(response).to have_http_status(:ok)
      end

      it 'muestra el formulario de nuevo requisito' do
        get new_admin_financial_product_benefit_requirement_path(product, benefit)
        expect(response.body).to include('requirement_type')
      end
    end

    describe 'POST create' do
      context 'con parametros validos - tipo min_transactions (CA2)' do
        it 'crea el requisito y redirige al show del beneficio' do
          expect do
            post admin_financial_product_benefit_requirements_path(product, benefit),
                 params: valid_params_min_transactions
          end.to change(FinancialProductBenefitRequirement, :count).by(1)

          expect(response).to redirect_to(admin_financial_product_benefit_path(product, benefit))
        end

        it 'asigna el tipo correcto' do
          post admin_financial_product_benefit_requirements_path(product, benefit),
               params: valid_params_min_transactions
          expect(FinancialProductBenefitRequirement.last.min_transactions?).to be true
        end
      end

      context 'con parametros validos - tipo min_transactions_with_amount (CA3)' do
        it 'crea el requisito con monto por transaccion' do
          expect do
            post admin_financial_product_benefit_requirements_path(product, benefit),
                 params: valid_params_with_amount
          end.to change(FinancialProductBenefitRequirement, :count).by(1)

          req = FinancialProductBenefitRequirement.last
          expect(req.min_transactions_with_amount?).to be true
          expect(req.min_amount_per_transaction).to eq(50.00)
        end
      end

      context 'con parametros validos - tipo accumulated_amount (CA4)' do
        it 'crea el requisito de monto acumulado' do
          expect do
            post admin_financial_product_benefit_requirements_path(product, benefit),
                 params: valid_params_accumulated
          end.to change(FinancialProductBenefitRequirement, :count).by(1)

          req = FinancialProductBenefitRequirement.last
          expect(req.accumulated_amount?).to be true
          expect(req.min_accumulated_amount).to eq(2500.00)
        end
      end

      context 'con parametros validos - tipo monthly_fee (CA5)' do
        it 'crea el requisito de cuota mensual' do
          expect do
            post admin_financial_product_benefit_requirements_path(product, benefit),
                 params: valid_params_monthly_fee
          end.to change(FinancialProductBenefitRequirement, :count).by(1)

          req = FinancialProductBenefitRequirement.last
          expect(req.monthly_fee?).to be true
          expect(req.monthly_fee_amount).to eq(179.00)
        end
      end

      context 'con parametros invalidos (CA9, CA10)' do
        it 'no crea el requisito y renderiza new' do
          expect do
            post admin_financial_product_benefit_requirements_path(product, benefit),
                 params: invalid_params
          end.not_to change(FinancialProductBenefitRequirement, :count)

          expect(response).to have_http_status(:unprocessable_entity)
        end

        it 'valida que min_transactions_count sea mayor que 0 (CA10)' do
          post admin_financial_product_benefit_requirements_path(product, benefit),
               params: {
                 financial_product_benefit_requirement: {
                   requirement_type: 'min_transactions',
                   min_transactions_count: '0'
                 }
               }
          expect(response).to have_http_status(:unprocessable_entity)
        end

        it 'valida que monthly_fee_amount sea mayor que 0 (CA9)' do
          post admin_financial_product_benefit_requirements_path(product, benefit),
               params: {
                 financial_product_benefit_requirement: {
                   requirement_type: 'monthly_fee',
                   monthly_fee_amount: '-100'
                 }
               }
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end

    describe 'GET edit' do
      it 'responde 200' do
        get edit_admin_financial_product_benefit_requirement_path(product, benefit, requirement)
        expect(response).to have_http_status(:ok)
      end

      it 'muestra el formulario con los datos del requisito' do
        get edit_admin_financial_product_benefit_requirement_path(product, benefit, requirement)
        expect(response.body).to include('requirement_type')
      end
    end

    describe 'PATCH update' do
      context 'con parametros validos' do
        it 'actualiza el requisito y redirige al show del beneficio' do
          patch admin_financial_product_benefit_requirement_path(product, benefit, requirement),
                params: {
                  financial_product_benefit_requirement: {
                    requirement_type: 'min_transactions',
                    min_transactions_count: '5'
                  }
                }

          expect(response).to redirect_to(admin_financial_product_benefit_path(product, benefit))
          expect(requirement.reload.min_transactions_count).to eq(5)
        end
      end

      context 'con parametros invalidos' do
        it 'no actualiza y renderiza edit' do
          patch admin_financial_product_benefit_requirement_path(product, benefit, requirement),
                params: invalid_params

          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end

    describe 'DELETE destroy (soft delete) (CA8)' do
      it 'desactiva el requisito (no lo elimina)' do
        expect do
          delete admin_financial_product_benefit_requirement_path(product, benefit, requirement)
        end.not_to change(FinancialProductBenefitRequirement, :count)

        expect(requirement.reload.active).to be false
      end

      it 'redirige al show del beneficio con notice' do
        delete admin_financial_product_benefit_requirement_path(product, benefit, requirement)
        expect(response).to redirect_to(admin_financial_product_benefit_path(product, benefit))
      end
    end
  end
end
