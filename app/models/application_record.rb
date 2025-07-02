# frozen_string_literal: true

# Application record model
class ApplicationRecord < ActiveRecord::Base
  include Utils
  primary_abstract_class
end
