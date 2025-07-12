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

  def amount_color_class(amount)
    if amount.positive?
      'text-emerald-400'
    elsif amount.negative?
      'text-red-400'
    else
      'text-bunker-400'
    end
  end

  def transaction_color_class(transaction_type_code)
    case transaction_type_code
    when 'income'
      'bg-emerald-400'
    when 'expense'
      'bg-orange-400'
    else
      'bg-purple-400'
    end
  end

  def transaction_text_color_class(transaction_type_code)
    case transaction_type_code
    when 'income'
      'text-emerald-400'
    when 'expense'
      'text-red-400'
    else
      'text-purple-400'
    end
  end

  def transaction_type_badge(transaction_type)
    case transaction_type&.code
    when 'income'
      { color: 'emerald', icon: '↗', text: 'Ingreso' }
    when 'expense'
      { color: 'red', icon: '↘', text: 'Gasto' }
    when 'transfer_out'
      { color: 'blue', icon: '→', text: 'Transferencia Salida' }
    when 'transfer_in'
      { color: 'purple', icon: '←', text: 'Transferencia Entrada' }
    when 'interest'
      { color: 'yellow', icon: '★', text: 'Interés' }
    when 'fee'
      { color: 'orange', icon: '!', text: 'Comisión' }
    else
      { color: 'bunker', icon: '?', text: 'Otro' }
    end
  end

  def budget_impact_percentage(transaction, budget)
    return 0 if budget.limit_amount.blank? || budget.limit_amount <= 0

    (transaction.amount.abs / budget.limit_amount * 100).round(1)
  end

  def category_month_total(transaction)
    start_date = transaction.transaction_date.beginning_of_month
    end_date = transaction.transaction_date.end_of_month

    Transaction.where(
      category: transaction.category,
      user: transaction.user,
      transaction_date: start_date..end_date
    ).sum(:amount).abs
  end

  def similar_transactions(transaction, limit = 3)
    Transaction.where(
      category: transaction.category,
      user: transaction.user
    ).where.not(id: transaction.id)
               .order(transaction_date: :desc)
               .limit(limit)
  end
end
