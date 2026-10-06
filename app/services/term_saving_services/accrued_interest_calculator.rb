# frozen_string_literal: true

module TermSavingServices
  # Calcula el rendimiento devengado de un TermSaving a una fecha de referencia,
  # respetando la frecuencia de devengo (ACCRUAL_FREQUENCY) del producto del
  # catalogo financiero con el que fue contratado (FEAT-024).
  #
  # Usa siempre +term_saving.rate_locked+ (la tasa congelada al contratar), nunca
  # la tasa vigente del catalogo: si el catalogo cambia su tasa despues de la
  # contratacion, el TermSaving ya emitido no se ve afectado.
  #
  # Formulas:
  #
  #   :daily       => A = P * ((1 + r/365) ** dias - 1)
  #                   Interes compuesto, se devenga dia a dia desde +started_at+.
  #
  #   :at_maturity => I = P * r * (term_days/365) si dias transcurridos >= term_days,
  #                   $0 en cualquier fecha anterior al vencimiento.
  #                   Interes simple, se liquida de una sola vez en +matures_at+.
  #
  # Sin +financial_product_id+ (TermSaving generico, sin producto del catalogo
  # asociado), la frecuencia por defecto es :at_maturity.
  class AccruedInterestCalculator
    DAYS_IN_YEAR = 365

    # @param term_saving [TermSaving]
    # @param reference_date [Date] fecha a la que se calcula el rendimiento acumulado
    # @return [Float] rendimiento devengado, redondeado a centavos
    def self.call(term_saving, reference_date: Date.current)
      new(term_saving, reference_date).call
    end

    def initialize(term_saving, reference_date)
      @term_saving = term_saving
      @reference_date = reference_date
    end

    def call
      return 0.0 unless elapsed_days.positive?

      accrual_frequency == :daily ? daily_interest : at_maturity_interest
    end

    private

    attr_reader :term_saving, :reference_date

    def elapsed_days
      days = (reference_date - term_saving.started_at).to_i
      days.negative? ? 0 : days
    end

    def daily_interest
      principal = term_saving.principal_amount
      rate = term_saving.rate_locked

      (principal * (((1 + (rate / DAYS_IN_YEAR))**elapsed_days) - 1)).round(2)
    end

    # El interes se calcula solo con base en term_days, sin importar cuanto haya
    # transcurrido de mas ni el status actual del TermSaving (matured/withdrawn):
    # una vez vencido, el rendimiento ya esta fijo y no sigue creciendo.
    def at_maturity_interest
      return 0.0 if elapsed_days < term_saving.term_days

      (term_saving.principal_amount * term_saving.rate_locked * (term_saving.term_days / DAYS_IN_YEAR.to_f)).round(2)
    end

    def accrual_frequency
      matched_product&.accrual_frequency || :at_maturity
    end

    def matched_product
      return nil unless term_saving.financial_product_id

      FinancialCatalogServices::Registry.all_products.find { |product| product.id == term_saving.financial_product_id }
    end
  end
end
