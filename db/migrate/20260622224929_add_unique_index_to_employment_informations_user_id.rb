# frozen_string_literal: true

# Reemplaza el índice no único de user_id por uno único para garantizar un registro por usuario.
class AddUniqueIndexToEmploymentInformationsUserId < ActiveRecord::Migration[7.2]
  def change
    remove_index :employment_informations, :user_id
    add_index :employment_informations, :user_id, unique: true
  end
end
