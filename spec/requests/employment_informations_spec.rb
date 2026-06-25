# frozen_string_literal: true

require 'rails_helper'

RSpec.describe '/employment_information', type: :request do
  let(:user) { create(:user) }
  let(:valid_attributes) do
    {
      job_title: 'Desarrollador de Software',
      start_date: Date.current - 2.years,
      gross_salary_amount: 25_000.0,
      calculation_periodicity: 'monthly_calculation',
      payment_frequency: 'biweekly_payment'
    }
  end
  let(:invalid_attributes) do
    { job_title: '', start_date: Date.current + 1.day, gross_salary_amount: -100 }
  end

  before { sign_in user }

  describe 'GET /new' do
    it 'renderiza la vista correctamente' do
      get new_employment_information_path
      expect(response).to be_successful
    end
  end

  describe 'POST /create' do
    context 'CA1: con atributos válidos' do
      it 'crea un nuevo EmploymentInformation' do
        expect do
          post employment_information_path, params: { employment_information: valid_attributes }
        end.to change(EmploymentInformation, :count).by(1)
      end

      it 'redirige al show después de crear' do
        post employment_information_path, params: { employment_information: valid_attributes }
        expect(response).to redirect_to(employment_information_path)
      end
    end

    context 'con atributos inválidos' do
      it 'no crea un nuevo EmploymentInformation' do
        expect do
          post employment_information_path, params: { employment_information: invalid_attributes }
        end.not_to change(EmploymentInformation, :count)
      end

      it 'renderiza el formulario con errores' do
        post employment_information_path, params: { employment_information: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'CA1: con combinacion incompatible de periodicidades' do
      it 'no crea el registro y renderiza formulario con error' do
        invalid_combo = valid_attributes.merge(
          calculation_periodicity: 'annual_calculation',
          payment_frequency: 'weekly_payment'
        )
        expect do
          post employment_information_path, params: { employment_information: invalid_combo }
        end.not_to change(EmploymentInformation, :count)
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'GET /show' do
    context 'cuando el usuario tiene información laboral' do
      let!(:employment_information) { create(:employment_information, user:) }

      it 'CA4: renderiza la vista de información laboral' do
        get employment_information_path
        expect(response).to be_successful
      end
    end

    context 'cuando el usuario no tiene información laboral' do
      it 'redirige al formulario de creación' do
        get employment_information_path
        expect(response).to redirect_to(new_employment_information_path)
      end
    end
  end

  describe 'GET /edit' do
    let!(:employment_information) { create(:employment_information, user:) }

    it 'renderiza la vista de edición' do
      get edit_employment_information_path
      expect(response).to be_successful
    end
  end

  describe 'PATCH /update' do
    let!(:employment_information) { create(:employment_information, user:) }

    context 'CA5: con atributos válidos' do
      it 'actualiza la información laboral' do
        patch employment_information_path, params: {
          employment_information: { job_title: 'Nuevo Puesto', calculation_periodicity: 'weekly_calculation',
                                    payment_frequency: 'weekly_payment' }
        }
        expect(employment_information.reload.job_title).to eq('Nuevo Puesto')
      end

      it 'redirige al show después de actualizar' do
        patch employment_information_path, params: {
          employment_information: valid_attributes.merge(job_title: 'Puesto Actualizado')
        }
        expect(response).to redirect_to(employment_information_path)
      end
    end

    context 'con atributos inválidos' do
      it 'no actualiza y renderiza edición' do
        patch employment_information_path, params: {
          employment_information: { job_title: '', gross_salary_amount: -1 }
        }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'autenticación' do
    before { sign_out user }

    it 'redirige al login si no está autenticado' do
      get new_employment_information_path
      expect(response).to redirect_to(new_user_session_path)
    end
  end
end
