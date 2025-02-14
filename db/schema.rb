# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_02_14_122632) do
  create_table "authors", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "books", force: :cascade do |t|
    t.string "title"
    t.integer "year_published"
    t.boolean "out_of_print"
    t.decimal "price"
    t.integer "author_id", null: false
    t.integer "supplier_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "print_year"
    t.index ["author_id"], name: "index_books_on_author_id"
    t.index ["supplier_id"], name: "index_books_on_supplier_id"
  end

  create_table "books_orders", id: false, force: :cascade do |t|
    t.integer "book_id", null: false
    t.integer "order_id", null: false
    t.index ["book_id"], name: "index_books_orders_on_book_id"
    t.index ["order_id"], name: "index_books_orders_on_order_id"
  end

  create_table "customers", force: :cascade do |t|
    t.string "name"
    t.string "email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "orders_count"
  end

  create_table "orders", force: :cascade do |t|
    t.integer "customer_id", null: false
    t.integer "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "total"
    t.index ["customer_id"], name: "index_orders_on_customer_id"
  end

  create_table "reviews", force: :cascade do |t|
    t.integer "customer_id", null: false
    t.integer "book_id", null: false
    t.integer "state"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["book_id"], name: "index_reviews_on_book_id"
    t.index ["customer_id"], name: "index_reviews_on_customer_id"
  end

  create_table "suppliers", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "books", "authors"
  add_foreign_key "books", "suppliers"
  add_foreign_key "books_orders", "books"
  add_foreign_key "books_orders", "orders"
  add_foreign_key "orders", "customers"
  add_foreign_key "reviews", "books"
  add_foreign_key "reviews", "customers"
end
