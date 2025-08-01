# frozen_string_literal: true

Sidekiq.configure_server do |config|
  config.redis = { url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/0') }

  # ¡IMPORTANTE! Incluir todas las colas
  config.queues = %w[critical recurring_transactions maintenance notifications default]
end
