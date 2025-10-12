# lib/tasks/seed_helpers/categories_seeder.rb
module Seeds
  class CategoriesSeeder < BaseSeeder
    class << self
      def create_categories
        log_progress("Iniciando creación de categorías...")

        handle_errors do
          data = load_json("categories.json")["records"]

          log_progress("Datos cargados: #{data.size} categorías")
          data.each do |category_data|
            create_category_group(category_data)
          end
        end

        log_progress("Categorías creadas exitosamente")
      end

      private

      def create_category_group(category_data)
        subcategories = category_data.delete("subcategories")

        icon = category_data.delete("icon")

        category = Category.find_or_initialize_by(name: category_data["name"])
        category.assign_attributes(category_data)
        category.icon = Catalog.joins(:group_catalog).find_by(group_catalogs: { code: 'transaction_icons' }, code: icon)
        category.save!

        log_progress("Creado/Actualizado grupo de categoría: #{category.name}")

        create_subcategories(category, subcategories)
      end

      def create_subcategories(category, subcategories)
        subcategories.each do |subcategory|
          icon = subcategory.delete("icon")
          subcategory["icon"] = Catalog.joins(:group_catalog).find_by(group_catalogs: { code: 'transaction_icons' }, code: icon)
          s = category.subcategories.find_or_initialize_by(name: subcategory["name"])
          s.update! subcategory
        end
      end
    end
  end
end
