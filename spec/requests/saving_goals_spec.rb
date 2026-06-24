# frozen_string_literal: true

require 'rails_helper'

RSpec.describe '/saving_goals', type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let!(:goal) { create(:saving_goal, user:, name: 'Meta Test', target_amount: 10_000) }

  let(:valid_params) { { saving_goal: { name: 'Enganche auto', target_amount: 80_000, deadline: '' } } }
  let(:invalid_params) { { saving_goal: { name: '', target_amount: -100 } } }

  describe 'sin autenticacion' do
    it 'redirige al login en GET /saving_goals' do
      get saving_goals_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'redirige al login en POST /saving_goals' do
      post saving_goals_path, params: valid_params
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe 'GET /saving_goals' do
    before { sign_in user }

    it 'retorna respuesta exitosa' do
      get saving_goals_path
      expect(response).to have_http_status(:ok)
    end

    it 'solo muestra las metas del usuario autenticado' do
      create(:saving_goal, user: other_user, name: 'Meta de otro usuario')

      get saving_goals_path
      expect(response.body).to include('Meta Test')
      expect(response.body).not_to include('Meta de otro usuario')
    end
  end

  describe 'GET /saving_goals/new' do
    before { sign_in user }

    it 'retorna respuesta exitosa' do
      get new_saving_goal_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'POST /saving_goals' do
    before { sign_in user }

    context 'con parametros validos' do
      it 'crea la meta y redirige' do
        expect do
          post saving_goals_path, params: valid_params
        end.to change(SavingGoal, :count).by(1)

        expect(response).to redirect_to(saving_goals_path)
      end

      it 'asigna la meta al usuario autenticado' do
        post saving_goals_path, params: valid_params
        expect(SavingGoal.last.user).to eq(user)
      end

      it 'crea la meta con estado activo por defecto' do
        post saving_goals_path, params: valid_params
        expect(SavingGoal.last.status).to eq('active')
      end
    end

    context 'con parametros invalidos' do
      it 'no crea la meta y renderiza new' do
        expect do
          post saving_goals_path, params: invalid_params
        end.not_to change(SavingGoal, :count)

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'GET /saving_goals/:id/edit' do
    before { sign_in user }

    it 'retorna respuesta exitosa para el dueno' do
      get edit_saving_goal_path(goal)
      expect(response).to have_http_status(:ok)
    end

    context 'cuando otro usuario intenta editar' do
      before { sign_in other_user }

      it 'retorna 404' do
        get edit_saving_goal_path(goal)
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'PATCH /saving_goals/:id' do
    before { sign_in user }

    context 'con parametros validos' do
      it 'actualiza la meta y redirige' do
        patch saving_goal_path(goal), params: { saving_goal: { name: 'Nombre actualizado', target_amount: 20_000 } }
        expect(response).to redirect_to(saving_goals_path)
        expect(goal.reload.name).to eq('Nombre actualizado')
      end
    end

    context 'con parametros invalidos' do
      it 'renderiza edit con error' do
        patch saving_goal_path(goal), params: { saving_goal: { name: '', target_amount: 10_000 } }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'cuando otro usuario intenta actualizar' do
      before { sign_in other_user }

      it 'retorna 404' do
        patch saving_goal_path(goal), params: { saving_goal: { name: 'Hack' } }
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'DELETE /saving_goals/:id' do
    before { sign_in user }

    it 'elimina la meta y redirige' do
      expect do
        delete saving_goal_path(goal)
      end.to change(SavingGoal, :count).by(-1)

      expect(response).to redirect_to(saving_goals_path)
    end

    context 'cuando otro usuario intenta eliminar' do
      before { sign_in other_user }

      it 'retorna 404 y no elimina' do
        expect do
          delete saving_goal_path(goal)
        end.not_to change(SavingGoal, :count)

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'PATCH /saving_goals/reorder' do
    let!(:goal2) { create(:saving_goal, user:, name: 'Segunda') }
    let!(:goal3) { create(:saving_goal, user:, name: 'Tercera') }

    before { sign_in user }

    it 'sin autenticacion retorna 401' do
      sign_out user
      patch reorder_saving_goals_path, params: { order: [goal.id, goal2.id, goal3.id] }, as: :json
      expect(response).to have_http_status(:unauthorized)
    end

    it 'actualiza el priority_order en el nuevo orden (CA3)' do
      patch reorder_saving_goals_path,
            params: { order: [goal3.id.to_s, goal.id.to_s, goal2.id.to_s] },
            as: :json

      expect(response).to have_http_status(:ok)
      parsed = response.parsed_body
      expect(parsed['success']).to be true

      expect(goal3.reload.priority_order).to eq(1)
      expect(goal.reload.priority_order).to eq(2)
      expect(goal2.reload.priority_order).to eq(3)
    end

    context 'cuando otro usuario intenta reordenar metas ajenas' do
      before { sign_in other_user }

      it 'retorna error 422 sin modificar las metas' do
        original_order = goal.priority_order

        patch reorder_saving_goals_path,
              params: { order: [goal.id.to_s] },
              as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(goal.reload.priority_order).to eq(original_order)
      end
    end
  end
end
