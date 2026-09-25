# frozen_string_literal: true

# Serializa una transaccion para la API movil (FEAT-037). `icon`/`color` son los
# valores de catalogo (emoji y clase de color Tailwind, ej. "blue-500").
class TransactionSerializer
  def initialize(transaction)
    @transaction = transaction
  end

  # rubocop:disable Metrics/AbcSize, Metrics/MethodLength -- lectura plana de campos, sin logica
  def as_json(*)
    {
      id: transaction.id,
      date: transaction.transaction_date,
      amount: transaction.amount.to_f,
      currency: transaction.currency&.code,
      description: transaction.description,
      category_name: transaction.category&.name,
      transaction_type: transaction.transaction_type&.code,
      icon: transaction.icon&.value,
      color: transaction.color&.value,
      created_at: transaction.created_at.iso8601,
      updated_at: transaction.updated_at.iso8601
    }
  end
  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

  private

  attr_reader :transaction
end
