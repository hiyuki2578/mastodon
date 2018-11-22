class AddCatToAccounts < ActiveRecord::Migration[5.2]
  def up
    add_column :accounts, :cat, :boolean, null:false, default: false
  end

  def down
    remove_column :accounts, :cat
  end
end