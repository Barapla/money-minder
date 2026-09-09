# frozen_string_literal: true

module FinancialCatalogServices
  module Nu
    # Fondo de ahorro Nu con tasa preferente condicionada a actividad transaccional (FEAT-028).
    #
    # El requisito de 1 transaccion mensual se cumple con CUALQUIER producto Nu del
    # usuario (debito o credito), no exclusivamente con esta Cajita Turbo. El catalogo
    # solo documenta el requisito de forma informativa: su cumplimiento no se valida
    # en codigo, Nu determina en su propio sistema si el saldo rinde 13% o cae a la
    # tasa de Nu Cajita (6.50%).
    class NuCajitaTurbo < BaseProduct
      ACCRUAL_FREQUENCY = :daily

      def initialize # rubocop:disable Metrics/MethodLength
        super(
          name: 'Nu Cajita Turbo',
          institution: 'Nu',
          product_type: :savings_fund,
          benefits: [
            { type: :annual_yield, unit: :percentage, value: 13.0, amount_cap: 25_000.0,
              requirement: 'Minimo 1 transaccion mensual con cualquier tarjeta Nu (debito o credito)',
              description: '13% anual sobre los primeros $25,000 MXN. Sin el requisito, el saldo rinde ' \
                            'la tasa de Nu Cajita (6.50%). Hasta 10 cajitas simultaneas por usuario.' }
          ]
        )
      end
    end
  end
end
