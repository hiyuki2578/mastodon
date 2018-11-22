class AddCatToAccounts < ActiveRecord::Migration[5.2]
  def up
    add_column :accounts, :cat, :boolean
    change_column_default :accounts, :cat, false
    change_column_null :accounts, :cat, false, false
  end

  def down
    remove_column :accounts, :cat
  end
end