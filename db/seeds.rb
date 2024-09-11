# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

require 'json'

# Leer el archivo JSON con las monedas

file = File.read(Rails.root.join('db', 'seeds', 'currencies.json'))
currencies_data = JSON.parse(file)

currencies_data.each do |currency_data|
  Currency.create!(
    name: currency_data['name'],
    code: currency_data['code'],
    symbol: currency_data['symbol']
  )
end

# Leer el archivo JSON con las categorías y subcategorías
file = File.read(Rails.root.join('db', 'seeds', 'categories.json'))
categories_data = JSON.parse(file)

# Crear categorías y subcategorías
categories_data['categories'].each do |category_data|
  # Crear la categoría principal
  parent_category = Category.create!(
    name: category_data['name'],
    description: category_data['description']
  )

  # Crear las subcategorías
  category_data['subcategories'].each do |subcategory_data|
    Category.create!(
      name: subcategory_data['name'],
      description: subcategory_data['description'],
      parent_category:
    )
  end
end

# Leer el archivo JSON con los roles

file = File.read(Rails.root.join('db', 'seeds', 'roles.json'))
roles_data = JSON.parse(file)

roles_data.each do |role_data|
  Role.create!(
    name: role_data['name']
  )
end

puts 'Categorías y subcategorías creadas exitosamente!'
