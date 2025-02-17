class Author < ApplicationRecord
  has_many :books, -> { order(year_published: :desc) }, strict_loading: true
end
