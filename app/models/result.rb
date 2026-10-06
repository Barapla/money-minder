# frozen_string_literal: true

# Encapsula el resultado de una operación de servicio (éxito o fallo).
class Result
  attr_reader :data, :record, :error, :message

  def self.success(data: nil, record: nil)
    new(success: true, data: data, record: record)
  end

  def self.failure(error:, message: nil)
    new(success: false, error: error, message: message)
  end

  def success?
    @success
  end

  def failure?
    !success?
  end

  private

  def initialize(success:, data: nil, record: nil, error: nil, message: nil)
    @success = success
    @data = data
    @record = record
    @error = error
    @message = message
  end
end
