class AddVisitToCustomer < ActiveRecord::Migration[8.0]
  def change
    add_column :customers, :visits, :integer
  end
end
