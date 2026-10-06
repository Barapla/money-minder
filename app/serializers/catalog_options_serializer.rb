# frozen_string_literal: true

# Opciones para los formularios de la app movil (transacciones, recordatorios,
# metas y perfil) en una sola respuesta. Las categorias por tipo siguen el
# mismo criterio que los selects del formulario web de transacciones.
class CatalogOptionsSerializer
  NON_EXPENSE_PARENTS = %w[Ingresos Transferencias].freeze

  def initialize(user)
    @user = user
  end

  # rubocop:disable Metrics/AbcSize, Metrics/MethodLength -- un campo por grupo de opciones
  def as_json(*)
    {
      transaction_types: catalog_entries('transaction_types').select { |t| %w[income expense].include?(t[:code]) },
      categories: {
        income: category_entries(Category.by_parent_category(NON_EXPENSE_PARENTS)),
        expense: category_entries(Category.exclude_categories_by_parent(NON_EXPENSE_PARENTS))
      },
      budgets: budget_entries,
      transaction_icons: catalog_entries('transaction_icons'),
      colors: catalog_entries('colors'),
      frequency_types: catalog_entries('frequency_types'),
      currencies: Currency.where(active: true).order(:name).map { |c| { id: c.id, code: c.code, name: c.name } }
    }
  end
  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

  private

  attr_reader :user

  def catalog_entries(group)
    Catalog.by_group(group).map { |c| { id: c.id, code: c.code, value: c.value } }
  end

  def category_entries(scope)
    scope.order(:name).pluck(:id, :name).map { |id, name| { id:, name: } }
  end

  def budget_entries
    user.budgets.where(active: true).includes(:budget_type).order(:name).map do |budget|
      { id: budget.id, name: budget.name, budget_type: budget.budget_type&.code, personal: budget.personal }
    end
  end
end
