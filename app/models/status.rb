class Status < ApplicationRecord
  belongs_to :group_catalog, class_name: 'GroupCatalog', foreign_key: 'group_catalog_id'
end
