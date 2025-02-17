class AddLockVersionToCustomers < ActiveRecord::Migration[8.0]
  def change
    add_column :customers, :lock_version, :integer
  end
end
