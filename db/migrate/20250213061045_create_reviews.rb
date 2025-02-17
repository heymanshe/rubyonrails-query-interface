class CreateReviews < ActiveRecord::Migration[8.0]
  def change
    create_table :reviews do |t|
      t.references :customer, null: false, foreign_key: true
      t.references :book, null: false, foreign_key: true
      t.integer :rating
      t.text :content
      t.integer :state, default: 0

      t.timestamps
    end
  end
end
