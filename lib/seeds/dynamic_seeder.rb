# frozen_string_literal: true

# lib/tasks/seed_helpers/dynamic_seeder.rb
module Seeds
  # Clase para la creación de registros dinámicos desde archivos JSON
  class DynamicSeeder < BaseSeeder
    class << self
      # Carga y procesa un archivo JSON para crear registros
      def seed_from_json(filename)
        log_progress("Iniciando seed dinámico desde #{filename}...")

        handle_errors do
          data = load_json(filename)
          model_name = data['model']
          records = data['records']

          model_class = model_name.constantize
          records.each do |record_data|
            create_record(model_class, record_data)
          end
        end

        log_progress("Seed completado exitosamente para #{filename}")
      end

      private

      def create_record(model_class, record_data)
        # Separamos las asociaciones de los atributos regulares
        associations, attributes = extract_associations(record_data, model_class)

        # Encontramos o inicializamos el registro principal
        record = find_or_initialize_record(model_class, attributes)
        record.save!

        log_progress("#{model_class} creado/actualizado: #{record.try(:name) || record.try(:id)}")

        # Procesamos las asociaciones
        process_associations(record, associations)
        record
      end

      def extract_associations(record_data, model_class = nil)
        associations = {}
        attributes = {}

        record_data.each do |key, value|
          if value.is_a?(Hash) || value.is_a?(Array)
            associations[key] = value
          else
            reflection = model_class&.reflect_on_association(key.to_sym)
            if reflection&.macro == :belongs_to && value.is_a?(String)
              attributes[key] = reflection.klass.find_by(code: value)
            else
              attributes[key] = value
            end
          end
        end

        [associations, attributes]
      end

      def find_or_initialize_record(model_class, attributes)
        # Determinamos qué atributos usar para buscar registros existentes
        unique_keys = model_class.try(:seed_unique_keys) || %i[name code key email id]
        search_attributes = attributes.stringify_keys.slice(*unique_keys.map(&:to_s))

        puts "Buscando o inicializando #{model_class} con atributos: #{search_attributes.inspect}"
        puts "Atributos completos: #{attributes.inspect}"

        return model_class.new(attributes) if search_attributes.empty?

        puts "Buscando #{model_class} con: #{search_attributes.inspect}"
        # Buscamos o inicializamos el registro con los atributos únicos

        model_class.find_or_initialize_by(search_attributes).tap do |record|
          record.assign_attributes(attributes)
        end
      end

      def process_associations(record, associations)
        associations.each do |association_name, association_data|
          reflection = record.class.reflect_on_association(association_name.to_sym)
          next unless reflection

          if association_data.is_a?(Array)
            process_collection_association(record, reflection, association_data)
          else
            process_single_association(record, reflection, association_data)
          end
        end
      end

      def process_collection_association(record, reflection, association_data)
        associated_records = association_data.map do |data|
          foreign_key = reflection.klass.foreign_key_for(record.class)
          data[foreign_key] = record.id
          create_record(reflection.klass, data)
        end

        record.send("#{reflection.name}=", associated_records)
      end

      def process_single_association(record, reflection, association_data)
        associated_record = create_record(reflection.klass, association_data)
        record.send("#{reflection.name}=", associated_record)
      end
    end
  end
end
