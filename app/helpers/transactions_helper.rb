# frozen_string_literal: true

# TransactionsHelper
module TransactionsHelper
  def headers_table_transactions_index
    [
      { name: 'Tipo de Transacción', size: 'min-w-[180px]' },
      { name: 'Monto', size: 'min-w-[120px]' },
      { name: 'Descripción', size: 'min-w-[120px]' },
      { name: 'Presupuesto', size: 'min-w-[120px]' },
      { name: 'Fecha de la transacción', size: 'min-w-[120px]' }
    ]
  end

  def values_table_transactions_format(transactions)
    transactions.map do |transaction|
      transaction_presenter = TransactionPresenter.new(transaction)
      [
        { type: 'icon', icon: transaction_presenter.icon, color: transaction_presenter.color,
          main_text: transaction_presenter.category, sub_text: transaction_presenter.transaction_type },
        { value: transaction_presenter.amount,
          div_color: transaction_presenter.color },
        { value: transaction_presenter.description },
        { value: transaction_presenter.budget },
        { value: transaction_presenter.transaction_date },
        {
          type: 'actions',
          actions: [
            { name: 'Ver', icon: 'eye', path: transaction_path(transaction),
              options: { class: 'hover:text-white' } },
            { name: 'Editar', icon: 'edit', path: edit_transaction_path(transaction),
              options: { class: 'hover:text-purple-400' } },
            {
              name: 'Eliminar', icon: 'trash', path: transaction_path(transaction),
              options: {
                class: 'hover:text-red-400',
                data: { turbo_method: :delete,
                        turbo_confirm: '¿Estás seguro de que quieres eliminar este presupuesto?' }
              }
            }
          ]
        }
      ]
    end
  end
end
