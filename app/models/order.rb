class Order < ApplicationRecord
  belongs_to :customer
  has_and_belongs_to_many :books, join_table: "books_orders"

  enum status: { shipped: 0, being_packed: 1, complete: 2, cancelled: 3 }

  scope :created_before, ->(time) { where("created_at < ?", time) }
end
