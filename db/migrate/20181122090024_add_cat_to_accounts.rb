class AddCatToAccounts < ActiveRecord::Migration[5.2]
  def up
    add_column :accounts, :cat, :boolean, null: false
    change_column_default :accounts, :cat, false
  end

  def down
    remove_column :accounts, :cat
  end
end