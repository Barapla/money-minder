# frozen_string_literal: true

module FinancialCatalogServices
  module Nu
    # Ahorro a plazo fijo Nu: 4 plazos disponibles, interes simple liquidado al
    # vencimiento, sin retiro anticipado bajo ninguna condicion (FEAT-028).
    #
    # Nu actualiza estas tasas cada 6-8 semanas aproximadamente: los valores de
    # TERM_TIERS son de referencia, verificar las tasas vigentes en el catalogo
    # oficial de Nu antes de capturar un TermSaving nuevo.
    class NuAhorroCongelado < BaseProduct
      ACCRUAL_FREQUENCY = :at_maturity

      TERM_TIERS = [
        { term_days: 7, annual_rate: 8.0, min_amount: 50.0, early_withdrawal: false },
        { term_days: 28, annual_rate: 10.0, min_amount: 50.0, early_withdrawal: false },
        { term_days: 90, annual_rate: 11.5, min_amount: 50.0, early_withdrawal: false },
        { term_days: 180, annual_rate: 12.5, min_amount: 50.0, early_withdrawal: false }
      ].freeze

      def initialize
        super(
          name: 'Nu Ahorro Congelado',
          institution: 'Nu',
          product_type: :term_saving,
          benefits: TERM_TIERS
        )
      end

      # @return [String] descripcion visible en el catalogo
      def description
        'Hasta 5 plazos activos simultaneos por usuario. Sin retiro anticipado bajo ninguna condicion.'
      end
    end
  end
end
