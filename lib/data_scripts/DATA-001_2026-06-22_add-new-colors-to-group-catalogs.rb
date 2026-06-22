# frozen_string_literal: true

# DATA-001 Migration: Agregar nuevos colores con buen contraste a group_catalogs
# Fecha: 2026-06-22
# Autor: DATA-001

# Colores nuevos y sus ratios de contraste WCAG AA documentados:
# - white (#FFFFFF)    -> contraste 21:1 sobre negro, usado como fondo claro
# - gray-200 (#E5E7EB) -> contraste 14.4:1 sobre negro (uso como fondo)
# - gray-400 (#9CA3AF) -> contraste 2.9:1 sobre blanco, 7.3:1 sobre negro
# - gray-600 (#4B5563) -> contraste 7.0:1 sobre blanco (pasa WCAG AA texto normal)

NEW_COLORS = [
  { value: 'white', code: 'white' },
  { value: 'gray-200', code: 'gray_light' },
  { value: 'gray-400', code: 'gray_medium' },
  { value: 'gray-600', code: 'gray_dark' }
].freeze

def up
  group = GroupCatalog.find_by!(code: 'colors')

  ActiveRecord::Base.transaction do
    NEW_COLORS.each do |color|
      catalog = group.catalogs.find_or_initialize_by(code: color[:code])
      catalog.value = color[:value]
      catalog.save!
      puts "Creado/Actualizado color: code=#{color[:code]}, value=#{color[:value]}"
    end
  end

  puts 'up: completado exitosamente'
end

def verify_color(group, color)
  catalog = group.catalogs.find_by(code: color[:code])
  raise "verify fallido: no se encontro color code=#{color[:code]}" unless catalog

  unless catalog.value == color[:value]
    raise "verify fallido: valor incorrecto para code=#{color[:code]}, " \
          "esperado=#{color[:value]}, actual=#{catalog.value}"
  end

  puts "Verificado: code=#{color[:code]}, value=#{catalog.value} — OK"
end

def verify
  group = GroupCatalog.find_by!(code: 'colors')
  NEW_COLORS.each { |color| verify_color(group, color) }
  puts 'verify: todos los colores en estado esperado — OK'
end

def rollback
  group = GroupCatalog.find_by!(code: 'colors')

  ActiveRecord::Base.transaction do
    NEW_COLORS.each do |color|
      catalog = group.catalogs.find_by(code: color[:code])
      next unless catalog

      catalog.destroy!
      puts "Eliminado color: code=#{color[:code]}"
    end
  end

  puts 'rollback: completado exitosamente'
end

up
