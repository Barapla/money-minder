# frozen_string_literal: true

# PaginationHelper provides methods for pagination functionality.
module PaginationHelper
  def total_pages(per_page, total_collections)
    (total_collections.to_f / per_page).ceil
  end

  def pagination_pages(numero, limite)
    resultado = []

    # Manejo del rango inferior
    inicio = [numero - 2, 1].max

    # Manejo del rango superior
    fin = [numero + 2, limite].min

    # Crear el arreglo con el rango
    (inicio..fin).each do |n|
      resultado << n
    end

    resultado
  end
end
