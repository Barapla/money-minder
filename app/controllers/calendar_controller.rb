# frozen_string_literal: true

# CalendarController
class CalendarController < ApplicationController
  def index
    @transactions = Transaction.report.where(transaction_date: Date.today.beginning_of_month..Date.today.end_of_month)
    set_income_and_expense_transactions
  end

  def set_month
    @date = safe_parse_date(params[:date])

    @transactions = Transaction
      .includes(:transaction_type, :category, :icon, :color)
      .where(transaction_date: @date.beginning_of_month..@date.end_of_month)

    @transactions = filter_transactions(@transactions, params[:filter])

    set_income_and_expense_transactions

    render layout: false if turbo_frame_request?
  end

  def day_details
    @date = safe_parse_date(params[:date])

    @transactions = Transaction
      .includes(:transaction_type, :category, :icon, :color)
      .where(transaction_date: @date.all_day)
      .order(transaction_date: :desc, created_at: :desc)

    @transactions = filter_transactions(@transactions, params[:filter])

    @expensed_total = @transactions.expense.sum(&:amount)
    @earned_total = @transactions.income.sum(&:amount)

    render layout: false if turbo_frame_request?
  end

  def advanced_search
    @date = safe_parse_date(params[:date])

    @filter = params[:filter]

    @income_check = true
    @expense_check = true
    @transfer_check = false

    if @filter.present? && @filter[:special].is_a?(Array)
      @income_check = @filter[:special].include?('income')
      @expense_check = @filter[:special].include?('expense')
      @transfer_check = @filter[:special].include?('transfer_and_income')
    end

    render layout: false if turbo_frame_request?
  end

  private

  def safe_parse_date(date_param)
    return Date.today unless date_param

    Date.parse(date_param)
  rescue ArgumentError
    Date.today
  end

  def filter_transactions(transactions, filter)
    if filter.present?
      if filter[:special].present?
        filter_types = filter[:special]

        # Aplicar scopes dinámicamente
        if filter_types.is_a?(Array) && filter_types.any?
          # Construir la query con OR para múltiples tipos
          scope_queries = filter_types.map do |type|
            case type
            when 'expense'
              Transaction.expense
            when 'income'
              Transaction.income
            when 'transfer_and_income'
              Transaction.transfers_and_income
            end
          end.compact

          # Combinar las queries con OR
          if scope_queries.any?
            combined_query = scope_queries.reduce do |combined, query|
              combined.or(query)
            end

            transactions = transactions.merge(combined_query)
          end
        end
      end
      if filter[:budgets].present? && filter[:budgets].is_a?(Array)
        transactions = transactions.joins(:budget).where(budgets: { id: filter[:budgets] })
      end
      if filter[:icons].present? && filter[:icons].is_a?(Array)
        transactions = transactions.joins(:category).where(categories: { code: filter[:icons] })
      end
      if filter[:min_amount].present?
        min_amount = filter[:min_amount].to_f
        transactions = transactions.where('amount >= ?', min_amount)
      end
      if filter[:max_amount].present?
        max_amount = filter[:max_amount].to_f
        transactions = transactions.where('amount <= ?', max_amount)
      end
    else
      transactions = transactions.report
    end
    transactions
  end

  def set_income_and_expense_transactions
    @income_transactions = @transactions.select { |t| t.transaction_type.code == 'income' }
    @expense_transactions = @transactions.select { |t| t.transaction_type.code == 'expense' }
  end
end
