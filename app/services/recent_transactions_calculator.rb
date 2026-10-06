# frozen_string_literal: true

# Retorna las ultimas transacciones del usuario para el dashboard movil (FEAT-038).
class RecentTransactionsCalculator
  LIMIT = 10

  def initialize(user)
    @user = user
  end

  def call
    user.transactions
        .includes(:category, :currency, :transaction_type)
        .order(transaction_date: :desc)
        .limit(LIMIT)
        .map { |transaction| entry_for(transaction) }
  end

  private

  attr_reader :user

  def entry_for(transaction)
    { id: transaction.id,
      description: transaction.description,
      amount: transaction.amount.to_f,
      currency: transaction.currency&.code,
      transaction_date: transaction.transaction_date,
      category_name: transaction.category&.name,
      category_color: transaction.category&.color&.value,
      transaction_type: transaction.transaction_type&.code }
  end
end
