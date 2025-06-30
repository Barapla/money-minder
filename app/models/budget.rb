# frozen_string_literal: true

# Budget Model
class Budget < ApplicationRecord
  belongs_to :budget_type, class_name: 'Catalog', foreign_key: 'budget_type_id'
  belongs_to :color, class_name: 'Catalog', foreign_key: 'color_id'
  belongs_to :icon, class_name: 'Catalog', foreign_key: 'icon_id'
end
