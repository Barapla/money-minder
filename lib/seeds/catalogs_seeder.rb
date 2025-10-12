# lib/tasks/seed_helpers/catalogs_seeder.rb
module Seeds
  class CatalogsSeeder < BaseSeeder
    class << self
      def create_catalogs(specific_catalog = nil)
        log_progress("Iniciando creación de catálogos...")

        handle_errors do
          data = load_json("group_catalogs.json")["records"]

          log_progress("Datos cargados: #{data.size} catálogos")
          data.each do |catalog_data|
            next if specific_catalog && catalog_data["code"] != specific_catalog
            create_catalog_group(catalog_data)
          end
        end

        log_progress("Catálogos creados exitosamente")
      end

      private

      def create_catalog_group(catalog_data)
        items = catalog_data.delete("catalogs")

        group_catalog = GroupCatalog.find_or_initialize_by(code: catalog_data["code"])
        group_catalog.assign_attributes(catalog_data)
        group_catalog.save!

        log_progress("Creado/Actualizado grupo de catálogo: #{group_catalog.name}")

        create_items(group_catalog, items) if items.present?
      end

      def create_items(group_catalog, items)
        items.each do |item|
          s = group_catalog.catalogs.find_or_initialize_by(code: item["code"])
          s.update! item
        end
      end
    end
  end
end
