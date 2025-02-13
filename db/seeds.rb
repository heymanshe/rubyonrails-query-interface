# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# Clear existing data
# Author.destroy_all
# Supplier.destroy_all
# Book.destroy_all
# Customer.destroy_all
# Order.destroy_all
# Review.destroy_all

# # Create Suppliers
# supplier1 = Supplier.create(name: "Penguin Publishing")
# supplier2 = Supplier.create(name: "HarperCollins")

# # Create Authors
# author1 = Author.create(name: "J.K. Rowling")
# author2 = Author.create(name: "George R.R. Martin")

# # Create Books
# book1 = Book.create(title: "Harry Potter", year_published: 2000, out_of_print: false, price: 499.99, author: author1, supplier: supplier1)
# book2 = Book.create(title: "Game of Thrones", year_published: 1996, out_of_print: false, price: 599.99, author: author2, supplier: supplier2)

# # Create Customers
# customer1 = Customer.create(name: "Alice", email: "alice@example.com")
# customer2 = Customer.create(name: "Bob", email: "bob@example.com")

# # Create Orders
# order1 = Order.create(customer: customer1, status: :shipped)
# order2 = Order.create(customer: customer2, status: :complete)

# # Associate Books with Orders
# order1.books << book1
# order2.books << book2

# # Create Reviews
# Review.create(customer: customer1, book: book1, state: :published)
# Review.create(customer: customer2, book: book2, state: :not_reviewed)
