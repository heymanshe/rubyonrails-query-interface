class AddTotalToOrders < ActiveRecord::Migration[8.0]
  def change
    add_column :orders, :total, :decimal
  end
end
