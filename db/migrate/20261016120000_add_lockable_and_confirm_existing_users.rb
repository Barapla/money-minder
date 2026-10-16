# frozen_string_literal: true

# Activa :lockable y :confirmable de Devise. Las columnas de confirmable ya
# existian desde la migracion original, pero nadie las usaba: los usuarios
# actuales se marcan como confirmados para que no pierdan el acceso.
class AddLockableAndConfirmExistingUsers < ActiveRecord::Migration[7.2]
  def up
    change_table :users, bulk: true do |t|
      t.integer :failed_attempts, default: 0, null: false
      t.string :unlock_token
      t.datetime :locked_at
    end
    add_index :users, :unlock_token, unique: true

    execute 'UPDATE users SET confirmed_at = created_at WHERE confirmed_at IS NULL'
  end

  def down
    remove_index :users, :unlock_token
    change_table :users, bulk: true do |t|
      t.remove :failed_attempts, :unlock_token, :locked_at
    end
  end
end
