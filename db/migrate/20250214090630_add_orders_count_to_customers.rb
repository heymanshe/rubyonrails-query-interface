class AddOrdersCountToCustomers < ActiveRecord::Migration[8.0]
  def change
    add_column :customers, :orders_count, :integer
  end
end
