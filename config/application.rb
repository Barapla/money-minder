require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module MoneyMinder
  # Application configuration should go into files in config/initializers
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0

    # Where the I18n library should search for translation files
    # Search nested folders in config/locales for better organization
    config.i18n.load_path += Dir[Rails.root.join('config', 'locales', '**', '*.{rb,yml}')]

    # Permitted locales available for the application
    config.i18n.available_locales = %i[es]

    # Set default locale
    config.i18n.locale = :es
    config.i18n.default_locale = :es

    # Use default language as fallback if translation is missing
    config.i18n.fallbacks = true

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")
  end
end
