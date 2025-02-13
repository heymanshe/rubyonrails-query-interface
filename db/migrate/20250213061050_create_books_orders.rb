class CreateBooksOrders < ActiveRecord::Migration[7.0]
  def change
    create_table :books_orders, id: false do |t|
      t.references :book, null: false, foreign_key: true
      t.references :order, null: false, foreign_key: true
    end
  end
end
