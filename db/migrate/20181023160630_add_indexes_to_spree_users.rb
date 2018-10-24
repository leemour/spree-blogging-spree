class AddIndexesToSpreeUsers < ActiveRecord::Migration[5.1]
  disable_ddl_transaction!

  def change
    add_index :spree_users, :name, algorithm: :concurrently
    add_index :spree_users, :surname, algorithm: :concurrently
    add_index :spree_users, :nickname, algorithm: :concurrently
  end
end
