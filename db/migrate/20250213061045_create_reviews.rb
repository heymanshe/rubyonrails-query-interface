class CreateReviews < ActiveRecord::Migration[8.0]
  def change
    create_table :reviews do |t|
      t.references :customer, null: false, foreign_key: true
      t.references :book, null: false, foreign_key: true
      t.integer :state

      t.timestamps
    end
  end
end
