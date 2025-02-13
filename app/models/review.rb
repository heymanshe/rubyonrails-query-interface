class Review < ApplicationRecord
  belongs_to :customer
  belongs_to :book

  enum state: { not_reviewed: 0, published: 1, hidden: 2 }
end
