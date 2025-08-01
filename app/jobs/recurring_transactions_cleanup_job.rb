# frozen_string_literal: true

# app/jobs/recurring_transactions_cleanup_job.rb
class RecurringTransactionsCleanupJob < ApplicationJob
  queue_as :maintenance

  def perform
    Rails.logger.info 'Starting recurring transactions cleanup...'

    cleaned_count = 0

    # Desactivar transacciones que han alcanzado su límite de ejecuciones
    expired_by_executions = RecurringTransaction.active.where(
      'max_executions IS NOT NULL AND execution_count >= max_executions'
    )

    expired_by_executions.update_all(
      status: RecurringTransaction.statuses[:completed],
      updated_at: Time.current
    )
    cleaned_count += expired_by_executions.count

    # Desactivar transacciones que han pasado su fecha de fin
    expired_by_date = RecurringTransaction.active.where(
      'end_date IS NOT NULL AND end_date < ?',
      Date.current
    )

    expired_by_date.update_all(
      status: RecurringTransaction.statuses[:completed],
      updated_at: Time.current
    )
    cleaned_count += expired_by_date.count

    Rails.logger.info "Cleaned up #{cleaned_count} completed recurring transactions"
  end
end
