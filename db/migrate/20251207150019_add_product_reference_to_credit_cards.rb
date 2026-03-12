class AddProductReferenceToCreditCards < ActiveRecord::Migration[7.0]
  def up
    add_reference :credit_cards, :credit_card_product, foreign_key: { to_table: :credit_card_products, name: 'fk_credit_cards_credit_card_product' }

    # Campos nuevos específicos del usuario
    add_column :credit_cards, :activation_date, :date
    add_column :credit_cards, :cutting_day_override, :integer
    add_column :credit_cards, :first_cycle_date, :date
    add_column :credit_cards, :credit_limit, :decimal, precision: 10, scale: 2
    add_column :credit_cards, :available_credit, :decimal, precision: 10, scale: 2
    add_column :credit_cards, :current_balance, :decimal, precision: 10, scale: 2, default: 0
  end

  def down
    remove_reference :credit_cards, :credit_card_product, foreign_key: { to_table: :credit_card_products, name: 'fk_credit_cards_credit_card_product' }

    remove_column :credit_cards, :activation_date
    remove_column :credit_cards, :cutting_day_override
    remove_column :credit_cards, :first_cycle_date
    remove_column :credit_cards, :credit_limit
    remove_column :credit_cards, :available_credit
    remove_column :credit_cards, :current_balance
  end
end
