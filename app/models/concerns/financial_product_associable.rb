# frozen_string_literal: true

# Permite asociar un instrumento financiero (Budget, CreditCard, SavingsFund) a un
# producto del catalogo mediante `financial_product_id` (FEAT-022). El producto se
# valida contra FinancialCatalogServices::Registry y, cuando esta presente, el nombre
# del instrumento se autogenera siguiendo el patron de User#create_personal_budget.
#
# CreditCard y SavingsFund no tienen columna `name` propia (el nombre vive en su
# Budget asociado), asi que el nombre generado se asigna a `self` si el modelo
# responde a `name=`, o a `budget` en caso contrario.
module FinancialProductAssociable
  extend ActiveSupport::Concern

  included do
    validates :financial_product_id, inclusion: {
      in: ->(_record) { FinancialCatalogServices::Registry.all_products.map(&:id) },
      allow_nil: true,
      message: :invalid_financial_product
    }

    before_validation :generate_name_from_financial_product, if: :financial_product_id?
  end

  private

  def generate_name_from_financial_product
    product = matched_financial_product
    owner = financial_product_owner
    return unless product && owner

    assign_generated_name("Cuenta #{product.name} de #{owner.first_name}")
  end

  def matched_financial_product
    FinancialCatalogServices::Registry.all_products.find { |p| p.id == financial_product_id }
  end

  def financial_product_owner
    respond_to?(:user) ? user : budget&.user
  end

  def assign_generated_name(generated_name)
    if respond_to?(:name=)
      self.name = generated_name
    else
      budget.name = generated_name
      budget.save if budget.persisted?
    end
  end
end
