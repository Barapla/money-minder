# frozen_string_literal: true

# app/jobs/recurring_transactions_job.rb
class RecurringTransactionsJob < ApplicationJob
  queue_as :recurring_transactions

  def perform
    Rails.logger.info "Starting recurring transactions processing at #{Time.current}"

    processed_count = 0
    error_count = 0

    # Usar el scope del modelo para obtener transacciones que necesitan procesarse
    pending_transactions = RecurringTransaction.due_for_processing
                                               .where('max_executions IS NULL OR execution_count < max_executions')

    Rails.logger.info "Found #{pending_transactions.count} pending recurring transactions"

    pending_transactions.find_each do |recurring_transaction|
      # Verificar que realmente pueda ejecutarse
      while recurring_transaction.should_process_transaction?
        Rails.logger.info "Queuing job for recurring transaction #{recurring_transaction.uuid} (ID: #{recurring_transaction.id})"
        # Encolar el trabajo para procesar la transacción recurrente
        ProcessSingleRecurringTransactionJob.perform_later(recurring_transaction.id, recurring_transaction.next_execution_date)
        # Actualizar la transacción recurrente
        update_recurring_transaction(recurring_transaction)
        Rails.logger.info "next_execution_date updated to #{recurring_transaction.next_execution_date} for #{recurring_transaction.uuid}"
        processed_count += 1
      end
    rescue StandardError => e
      Rails.logger.error "Error queuing recurring transaction #{recurring_transaction.uuid}: #{e.message}"
      error_count += 1
    end

    Rails.logger.info "Recurring transactions processing completed: Processed: #{processed_count}, Errors: #{error_count}"
  end

  private

  def update_recurring_transaction(recurring_transaction)
    new_execution_count = recurring_transaction.execution_count + 1
    next_date = calculate_next_execution_date(recurring_transaction)

    Rails.logger.info "next_execution_date for #{recurring_transaction.uuid} (ID: #{recurring_transaction.id}) is #{next_date}"

    updates = {
      execution_count: new_execution_count,
      next_execution_date: next_date
    }

    # Si ha alcanzado el máximo de ejecuciones, desactivar
    if recurring_transaction.max_executions.present? &&
       new_execution_count >= recurring_transaction.max_executions
      updates.merge!(
        active: false,
        status: :completed
      )
    end

    # Si la próxima fecha es después de la fecha de fin, desactivar
    if recurring_transaction.end_date.present? &&
       next_date > recurring_transaction.end_date
      updates.merge!(
        active: false,
        status: :completed
      )
    end

    recurring_transaction.update!(updates)
  end

  def calculate_next_execution_date(recurring_transaction)
    current_date = recurring_transaction.next_execution_date

    case recurring_transaction.frequency
    when 'daily'
      current_date + 1.day
    when 'weekly'
      current_date + 1.week
    when 'bi_weekly'
      current_date + 2.weeks
    when 'monthly'
      current_date + 1.month
    when 'bi_monthly'
      current_date + 2.months
    when 'quarterly'
      current_date + 3.months
    when 'semi_annually'
      current_date + 6.months
    when 'annually'
      current_date + 1.year
    else
      # Fallback por si acaso
      current_date + 1.day
    end
  end
end
