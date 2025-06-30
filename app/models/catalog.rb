# frozen_string_literal: true

# Catalog Model
class Catalog < ApplicationRecord
  belongs_to :group_catalog

  scope :by_group, lambda { |group_name|
    joins(:group_catalog)
      .where(group_catalogs: { code: group_name })
      .order(:code)
  }
end
