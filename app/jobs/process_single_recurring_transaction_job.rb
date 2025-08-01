# frozen_string_literal: true

# app/jobs/process_single_recurring_transaction_job.rb
class ProcessSingleRecurringTransactionJob < ApplicationJob
  queue_as :recurring_transactions

  retry_on StandardError, wait: 5.minutes, attempts: 3

  def perform(recurring_transaction_id, transaction_date)
    recurring_transaction = RecurringTransaction.find(recurring_transaction_id)

    Rails.logger.info "Processing recurring transaction #{recurring_transaction.uuid} (ID: #{recurring_transaction_id})"

    ActiveRecord::Base.transaction do
      # Crear la nueva transacción
      transaction_attributes = build_transaction_attributes(recurring_transaction, transaction_date)
      transaction = Transaction.create!(transaction_attributes)

      Rails.logger.info "✓ Created transaction #{transaction.uuid} from recurring #{recurring_transaction.uuid}"

      # Opcional: Enviar notificación si auto_approve es false
      TransactionApprovalNotificationJob.perform_later(transaction.id) unless recurring_transaction.auto_approve
    end
  rescue ActiveRecord::RecordNotFound
    Rails.logger.warn "Recurring transaction #{recurring_transaction_id} not found"
  rescue StandardError => e
    Rails.logger.error "Error processing recurring transaction #{recurring_transaction_id}: #{e.message}"

    # Marcar como error después de todos los reintentos
    recurring_transaction&.update(status: :error) if executions >= self.class.retry_attempts

    raise e
  end

  private

  def build_transaction_attributes(recurring_transaction, transaction_date)
    base_attributes = {
      user_id: recurring_transaction.user_id,
      transaction_date:,
      recurring_transaction_id: recurring_transaction.id
    }

    # Agregar atributos desde transaction_options
    if recurring_transaction.transaction_options.present?
      transaction_options = recurring_transaction.transaction_options.symbolize_keys
      # Remover el ID si existe para evitar conflictos
      transaction_options.delete(:id)
      base_attributes.merge!(transaction_options)
    end

    base_attributes
  end
end
