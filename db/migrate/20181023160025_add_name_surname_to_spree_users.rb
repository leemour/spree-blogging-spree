class AddNameSurnameToSpreeUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :spree_users, :name, :string
    add_column :spree_users, :surname, :string
  end
end
