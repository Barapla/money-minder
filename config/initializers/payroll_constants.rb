# frozen_string_literal: true

PayrollConstants = YAML.load_file(Rails.root.join('config/payroll_constants.yml'), aliases: true)[Rails.env]
                       .deep_symbolize_keys
                       .freeze
