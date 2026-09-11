# frozen_string_literal: true

module ChatbotServices
  # Liquidez actual: efectivo + debito + fondos de ahorro - deuda de tarjetas de credito.
  # Reutiliza LiquidityServices::Calculator en vez de duplicar las queries de balance.
  class LiquidityCalculator
    CACHE_TTL = 5.minutes
    ASSUMPTIONS = [
      'Se considera el saldo actual de cuentas de efectivo, debito y fondos de ahorro activos.',
      'La deuda de tarjetas de credito corresponde al ciclo vigente de cada tarjeta activa.'
    ].freeze
    NEGATIVE_LIQUIDITY_WARNING = 'Tu deuda de tarjetas de crédito supera tu liquidez disponible.'

    def initialize(user:)
      @user = user
    end

    def calculate
      data = balances
      Result.success(data: { result: result_hash(data), assumptions: ASSUMPTIONS, warnings: warnings_for(data) })
    end

    private

    attr_reader :user

    def balances
      Rails.cache.fetch("chatbot/liquidity/#{user.id}", expires_in: CACHE_TTL) do
        calc = LiquidityServices::Calculator.new(user)
        {
          cash: calc.cash_balance.to_f,
          debit: calc.debit_balance.to_f,
          savings: calc.savings_balance.to_f,
          credit_debt: calc.credit_debt.to_f,
          total: calc.total_available_money.to_f
        }
      end
    end

    def result_hash(data)
      {
        primary_metric: data[:total].round(2),
        breakdown: [
          { label: 'Efectivo', amount: data[:cash] },
          { label: 'Débito', amount: data[:debit] },
          { label: 'Fondos de ahorro', amount: data[:savings] },
          { label: 'Deuda de tarjetas de crédito', amount: -data[:credit_debt] }
        ]
      }
    end

    def warnings_for(data)
      data[:total].negative? ? [NEGATIVE_LIQUIDITY_WARNING] : []
    end
  end
end
