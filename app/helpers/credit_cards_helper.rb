# frozen_string_literal: true

# Acciones del detalle de una tarjeta de credito.
module CreditCardsHelper
  # Pagar una tarjeta es una transferencia: el dinero sale de otro presupuesto
  # (fondo de ahorro, cuenta de debito) y entra a la tarjeta. El origen lo elige
  # el usuario en el formulario; aqui solo se fija el destino y el monto.
  def pay_card_path(budget, amount = nil)
    new_transaction_path(transaction_type: 'transfer', related_budget_id: budget.id,
                         amount: amount&.round(2))
  end

  # Aportar a un fondo es lo mismo: una transferencia con el fondo como destino.
  def fund_contribution_path(budget)
    new_transaction_path(transaction_type: 'transfer', related_budget_id: budget.id)
  end
end
