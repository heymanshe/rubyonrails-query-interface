class Review < ApplicationRecord
  belongs_to :customer
  belongs_to :book
  validates :rating, presence: true
  validates :content, presence: true

  # enum state: { not_reviewed: 0, published: 1, hidden: 2 }
end
