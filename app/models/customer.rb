class Customer < ApplicationRecord
  has_many :orders
  has_many :reviews

  self.locking_column = :lock_customer_column

  validates :orders_count, presence: true
end
