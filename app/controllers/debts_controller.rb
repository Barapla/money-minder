# frozen_string_literal: true

# Deudas propias y ajenas. El saldo se calcula desde las transacciones ligadas
# (ver Debt), asi que aqui no hay contadores que mantener.
class DebtsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_debt, only: %i[show edit update destroy settle]

  def index
    @index_presenter = DebtsIndexPresenter.new(current_user)
  end

  def show
    @allocations = @debt.debt_allocations
                        .includes(transaction_record: %i[transaction_type budget icon color])
                        .sort_by { |item| item.transaction_date || Date.new(0) }
                        .reverse
    @candidates = @debt.candidate_transactions
  end

  def new
    # Sin fecha por defecto: preseleccionar hoy le pondria una fecha falsa a las
    # deudas sueltas, que es justo lo que no tienen.
    @debt = current_user.debts.new(direction: params[:direction].presence || :receivable)
  end

  def edit; end

  def create
    @debt = current_user.debts.new(debt_params)

    # La deuda y su recordatorio van juntos: si el recordatorio no se puede armar
    # no queremos una deuda a plazos sin nada en el calendario.
    saved = ActiveRecord::Base.transaction do
      @debt.save && build_reminder != false
    end

    if saved
      redirect_to @debt, notice: t('.success')
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @debt.update(debt_params)
      build_reminder
      redirect_to @debt, notice: t('.success')
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @debt.destroy
    redirect_to debts_path, notice: t('.success')
  end

  # Cerrar a mano una deuda: perdonada, incobrable o pagada fuera de la app.
  def settle
    @debt.settle!
    redirect_to @debt, notice: t('.success')
  end

  private

  def set_debt
    @debt = current_user.debts.find(params[:id])
  end

  # Devuelve false (y aborta la transaccion) si el recordatorio no se pudo armar.
  def build_reminder
    DebtServices::ReminderBuilder.new(@debt, **reminder_params).call
    true
  rescue ActiveRecord::RecordInvalid => e
    @debt.errors.add(:base, t('debts.errors.reminder_failed', message: e.record.errors.full_messages.to_sentence))
    false
  end

  def reminder_params
    {
      frequency: params[:frequency].presence || 'weekly',
      frequency_value: params[:frequency_value].presence || 1,
      day_of_week: params[:day_of_week].presence,
      day_of_month: params[:day_of_month].presence
    }
  end

  def debt_params
    params.require(:debt).permit(:direction, :name, :counterparty, :principal_amount,
                                 :installment_amount, :started_on, :expected_end_on, :notes,
                                 :budget_id, :category_id, :color_id, :icon_id, :status)
  end
end
