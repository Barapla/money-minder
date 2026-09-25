# frozen_string_literal: true

# Ligar movimientos a una deuda, ajustar cuanto abona cada uno y desligarlos.
# Vive bajo la deuda porque es ahi donde se ve el saldo, no en el alta de la
# transaccion.
class DebtAllocationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_debt
  before_action :set_allocation, only: %i[update destroy]

  def create
    allocation = @debt.debt_allocations.new(allocation_params)

    if allocation.save
      redirect_to @debt, notice: t('.success')
    else
      redirect_to @debt, alert: allocation.errors.full_messages.to_sentence
    end
  end

  def update
    if @allocation.update(allocation_params.slice(:amount))
      redirect_to @debt, notice: t('.success')
    else
      redirect_to @debt, alert: @allocation.errors.full_messages.to_sentence
    end
  end

  def destroy
    @allocation.destroy
    redirect_to @debt, notice: t('.success')
  end

  private

  def set_debt
    @debt = current_user.debts.find(params[:debt_id])
  end

  def set_allocation
    @allocation = @debt.debt_allocations.find(params[:id])
  end

  # El movimiento tiene que ser del usuario: sin esto se podria ligar el de otro
  # mandando un id a mano.
  def allocation_params
    permitted = params.require(:debt_allocation).permit(:transaction_id, :amount)
    return permitted if permitted[:transaction_id].blank?

    permitted.merge(transaction_id: current_user.transactions.find(permitted[:transaction_id]).id)
  end
end
