# frozen_string_literal: true

module FinancialCatalogServices
  # Punto de consulta centralizado del catalogo financiero (FEAT-021).
  #
  # Envuelve FinancialCatalogServices::Catalog.all_products para permitir filtrar
  # por tipo de instrumento o institucion sin acoplar a las clases de producto
  # especificas. Para agregar un producto nuevo al Registry no se toca esta clase:
  # se agrega la clase de producto (heredando de BaseProduct) y se registra en
  # FinancialCatalogServices::Catalog.all_products; aparecera automaticamente aqui.
  #
  # @example Consultar todo el catalogo
  #   FinancialCatalogServices::Registry.all_products
  #
  # @example Filtrar por tipo
  #   FinancialCatalogServices::Registry.by_type(FinancialCatalogServices::Registry::CREDIT)
  #
  # @example Encadenar filtros
  #   FinancialCatalogServices::Registry.by_type(Registry::DEBIT).by_institution('Klar').to_a
  class Registry
    CASH = :cash
    DEBIT = :debit
    CREDIT = :credit
    SAVINGS = :savings_fund

    class << self
      def all_products
        Catalog.all_products
      end

      def by_type(type)
        FilteredCollection.new(all_products).by_type(type)
      end

      def by_institution(institution)
        FilteredCollection.new(all_products).by_institution(institution)
      end
    end

    # Coleccion de productos filtrada que permite seguir encadenando filtros.
    class FilteredCollection
      include Enumerable

      def initialize(products)
        @products = products
      end

      def by_type(type)
        FilteredCollection.new(@products.select { |product| product.product_type.to_s == type.to_s })
      end

      def by_institution(institution)
        FilteredCollection.new(@products.select { |product| product.institution.to_s == institution.to_s })
      end

      def each(&block)
        @products.each(&block)
      end

      def to_a
        @products
      end
    end
  end
end
