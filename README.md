# 1. Query Interface Overview

- Active Record is the ORM layer in Rails that abstracts raw SQL queries, making database interactions more convenient. It supports multiple database systems, including MySQL, MariaDB, PostgreSQL, and SQLite.

**Models & Relationships**

  **Author**

  ```ruby
  class Author < ApplicationRecord
    has_many :books, -> { order(year_published: :desc) }
  end
  ```

  **Book**

  ```ruby
  class Book < ApplicationRecord
    belongs_to :supplier
    belongs_to :author
    has_many :reviews
    has_and_belongs_to_many :orders, join_table: "books_orders"

    scope :in_print, -> { where(out_of_print: false) }
    scope :out_of_print, -> { where(out_of_print: true) }
    scope :old, -> { where(year_published: ...50.years.ago.year) }
    scope :out_of_print_and_expensive, -> { out_of_print.where("price > 500") }
    scope :costs_more_than, ->(amount) { where("price > ?", amount) }
  end
  ```

  **Customer**

  ```ruby
  class Customer < ApplicationRecord
    has_many :orders
    has_many :reviews
  end
  ```

  **Order**

  ```ruby
  class Order < ApplicationRecord
    belongs_to :customer
    has_and_belongs_to_many :books, join_table: "books_orders"

    enum :status, [:shipped, :being_packed, :complete, :cancelled]

    scope :created_before, ->(time) { where(created_at: ...time) }
  end
  ```

  **Review**

  ```ruby
  class Review < ApplicationRecord
    belongs_to :customer
    belongs_to :book

    enum :state, [:not_reviewed, :published, :hidden]
  end
  ```

  **Supplier**

  ```ruby
  class Supplier < ApplicationRecord
    has_many :books
    has_many :authors, through: :books
  end
  ```

# 2. Retrieving Objects from Database

### Finder Methods Overview

 - **Common Methods:**

    - **`find`** – Retrieves an object by primary key(s), raises `ActiveRecord::RecordNotFound` if not found.
    - **`take`** – Retrieves a record without ordering, returns `nil` if not found.
    - **`first`** – Retrieves the first record ordered by primary key.
    - **`last`** – Retrieves the last record ordered by primary key.
    - **`find_by`** – Finds the first record matching specified conditions, returns `nil` if not found.

 - **Collection Methods**:

    - **`where`** – Returns an `ActiveRecord::Relation` for filtering records.
    - **`group`** – Groups query results.
    - **`order`** – Orders query results.
    - **`limit`** – Restricts the number of records returned.
    - **`offset`** – Skips a specified number of records.
    - **`joins / includes`** – Joins related tables for queries.

## 2.1 Retrieving a Single Object

**`find`**

- Finds a record by primary key(s):

```bash
customer = Customer.find(10)
```

- SQL equivalent:

```bash
SELECT * FROM customers WHERE customers.id = 10 LIMIT 1;
```

- Finds multiple records by passing an array:

```bash
customers = Customer.find([1, 10])
```

**`take`**

- Retrieves a single record:

```bash
customer = Customer.take
```

- SQL equivalent:

```bash
SELECT * FROM customers LIMIT 1;
```

- `take(n)` retrieves up to `n` records:

```bash
customers = Customer.take(2)
```

**`first`**

- Retrieves the first record ordered by primary key:

```bash
customer = Customer.first
```

- SQL equivalent:

```bash
SELECT * FROM customers ORDER BY customers.id ASC LIMIT 1;
```

- `first(n)` retrieves the first `n` records:

```bash
customers = Customer.first(3)
```

**`last`**

- Retrieves the last record ordered by primary key:

```bash
customer = Customer.last
```

- SQL equivalent:

```bash
SELECT * FROM customers ORDER BY customers.id DESC LIMIT 1;
```

- `last(n)` retrieves the last `n` records:

```bash
customers = Customer.last(3)
```

**`find_by`**

- Finds the first record matching conditions:

```bash
customer = Customer.find_by(first_name: 'Lifo')
```

- SQL equivalent:

```bash
SELECT * FROM customers WHERE customers.first_name = 'Lifo' LIMIT 1;
```

- Returns `nil` if no record is found.

- `find_by!` raises `ActiveRecord::RecordNotFound` if no record is found.

### Notes on Composite Primary Keys

- When using composite primary keys, `find` requires an array:

```bash
customer = Customer.find([3, 17])
```

- SQL equivalent:

```bash
SELECT * FROM customers WHERE store_id = 3 AND id = 17;
```

- `find_by(id: value)` may not behave as expected with composite primary keys. Instead, use `id_value`:

```bash
customer = Customer.find_by(id: customer.id_value)
```

## 2.2 Retrieving Multiple Objects in Batches

- Iterating over large sets of records at once `(Customer.all.each)` can consume too much memory.

- Rails provides `find_each` and `find_in_batches` to process records in memory-efficient batches.

**`find_each`**

- Retrieves records in batches and yields each record individually.

- Default batch size: **1000 records**.

- Works on model classes and relations without ordering.

```bash
Customer.find_each do |customer|
  NewsMailer.weekly(customer).deliver_now
end
```

- Options for `find_each`

- **`:batch_size`** – Sets batch size (default: `1000`).

```bash
Customer.find_each(batch_size: 5000) do |customer|
  NewsMailer.weekly(customer).deliver_now
end
```

- **`:start`** – Specifies starting ID.

```bash
Customer.find_each(start: 2000) do |customer|
  NewsMailer.weekly(customer).deliver_now
end
```

**`:finish`** – Specifies ending ID.

```bash
Customer.find_each(start: 2000, finish: 10000) do |customer|
  NewsMailer.weekly(customer).deliver_now
end
```

- **`:error_on_ignore`** – Raises error if order is present.

- **`:order`** – Specifies sorting order (:asc or :desc).

```bash
Customer.find_each(order: :desc) do |customer|
  NewsMailer.weekly(customer).deliver_now
end
```

### find_in_batches

- Similar to `find_each`, but yields entire batches as arrays instead of individual records.

- Default batch size: `1000 records`.

```bash
Customer.find_in_batches do |customers|
  export.add_customers(customers)
end
```

### Options for `find_in_batches`

- **`:batch_size`** – Sets batch size.

```bash
Customer.find_in_batches(batch_size: 2500) do |customers|
  export.add_customers(customers)
end
```

- **`:start`** – Specifies starting ID.

```bash
Customer.find_in_batches(batch_size: 2500, start: 5000) do |customers|
  export.add_customers(customers)
end
```

- **`:finish`** – Specifies ending ID.

```bash
Customer.find_in_batches(finish: 7000) do |customers|
  export.add_customers(customers)
end
```

- **`:error_on_ignore`** – Raises error if order is present.

| Method          | Use Case                                              |
|----------------|-------------------------------------------------------|
| `find_each`    | When records should be processed individually.        |
| `find_in_batches` | When records should be processed in groups (e.g., bulk updates/exports). |


- `find_each` and `find_in_batches` require an order on the primary key `(id)`.

- If a relation has ordering, Rails **ignores it** or **raises an error** depending on `error_on_ignore` setting.

- Ideal for processing **large datasets** without excessive memory consumption.


# 3. Where Conditions

## 3.1 Pure String Conditions

- The where method allows specifying conditions to limit records (SQL WHERE clause).

```bash
Book.where("title = 'Introduction to Algorithms'").
```

- Risk of SQL Injection: Using string interpolation `(Book.where("title LIKE '%#{params[:title]}%'"))` is unsafe.

- Avoid pure string conditions and use safer alternatives like array conditions.

## 3.2 Array Conditions

Use `?` placeholders for safe query execution.

```bash
Book.where("title = ?", params[:title])
```

- Supports multiple conditions:

```bash
Book.where("title = ? AND out_of_print = ?", params[:title], false)
```

- Avoid direct variable interpolation `(Book.where("title = #{params[:title]}"))` as it exposes the database to SQL injection.

### 3.2.1 Placeholder Conditions

- Use named placeholders for better readability:

```ruby
Book.where("created_at >= :start_date AND created_at <= :end_date",
  { start_date: params[:start_date], end_date: params[:end_date] })
```

### 3.2.2 Conditions Using LIKE

- LIKE conditions should be sanitized to avoid unexpected behavior.

- Example (unsafe): 

```bash
Book.where("title LIKE ?", params[:title] + "%")
```

- Safe approach:

```bash
Book.where("title LIKE ?", Book.sanitize_sql_like(params[:title]) + "%")
```

## 3.3 Hash Conditions

- Hash conditions allow passing a hash with field names as keys and values as conditions.

- Supports equality, range, and subset checks.

### 3.3.1 Equality Conditions

```bash
Book.where(out_of_print: true)

# SQL: 
SELECT * FROM books WHERE books.out_of_print = 1
```

- Works with string keys:

```bash
Book.where("out_of_print" => true)
```

- Works with **belongs_to relationships**:

```bash
author = Author.first
Book.where(author: author)
Author.joins(:books).where(books: { author: author })
```

- **Tuple-like syntax** (useful for composite keys):

```bash
Book.where([:author_id, :id] => [[15, 1], [15, 2]])
```

### 3.3.2 Range Conditions

```bash
Book.where(created_at: (Time.now.midnight - 1.day)..Time.now.midnight)

# SQL:

SELECT * FROM books WHERE books.created_at BETWEEN 'YYYY-MM-DD HH:MM:SS' AND 'YYYY-MM-DD HH:MM:SS'
```

- Beginless and Endless Ranges:

```bash
Book.where(created_at: (Time.now.midnight - 1.day)..)

# SQL: 

WHERE books.created_at >= 'YYYY-MM-DD HH:MM:SS'
```

### 3.3.3 Subset Conditions

- IN Queries:

```bash
Customer.where(orders_count: [1, 3, 5])

# SQL: 

SELECT * FROM customers WHERE customers.orders_count IN (1,3,5)
```

## 3.4 NOT Conditions

- NOT IN Queries:

```bash
Customer.where.not(orders_count: [1, 3, 5])

# SQL: 

WHERE customers.orders_count NOT IN (1,3,5)
```

- Handling NULL values:

```bash
Customer.where.not(nullable_country: "UK")

# If column contains NULL, result may be empty
```

## 3.5 OR Conditions

- Combining Queries with OR:

```bash
Customer.where(last_name: "Smith").or(Customer.where(orders_count: [1, 3, 5]))

# SQL: 

WHERE customers.last_name = 'Smith' OR customers.orders_count IN (1,3,5)
```

## 3.6 AND Conditions


- Chaining Conditions:

```bash
Customer.where(last_name: "Smith").where(orders_count: [1, 3, 5])

# SQL: 

WHERE customers.last_name = 'Smith' AND customers.orders_count IN (1,3,5)
```

- Using and for logical intersection:

```bash
Customer.where(id: [1, 2]).and(Customer.where(id: [2, 3]))

# SQL: 

WHERE customers.id IN (1, 2) AND customers.id IN (2, 3)
```

# 4. Ordering Records

**Basic Ordering**

- To retrieve records in a specific order, use the `order` method.

```bash
Book.order(:created_at)  # Orders by created_at in ascending order
Book.order("created_at")
```

**Specifying Order Direction**


- You can specify `ASC` (ascending) or `DESC` (descending):

```bash
Book.order(created_at: :desc)  # Descending order
Book.order(created_at: :asc)   # Ascending order
Book.order("created_at DESC")
Book.order("created_at ASC")
```

**Ordering by Multiple Fields**

- To order by multiple columns:

```bash
Book.order(title: :asc, created_at: :desc)
Book.order(:title, created_at: :desc)
Book.order("title ASC, created_at DESC")
Book.order("title ASC", "created_at DESC")
```

**Chaining Multiple Order Calls**

- You can call `order` multiple times; subsequent orders are appended:

```bash
Book.order("title ASC").order("created_at DESC")

# Generates: ORDER BY title ASC, created_at DESC
```

**Ordering from a Joined Table**

- To order by fields from associated tables:

```bash
Book.includes(:author).order(books: { print_year: :desc }, authors: { name: :asc })
Book.includes(:author).order("books.print_year desc", "authors.name asc")
```

**Ordering with Select, Pluck, and IDs**

- When using `select`, `pluck`, or `ids` with `distinct`, ensure that the fields used in the `order` clause are included in the `select` list. Otherwise, an `ActiveRecord::StatementInvalid` exception may occur.

# 5. Selecting Specific Fields

**Selecting Specific Columns**

- By default, Model.find selects all fields (SELECT *). To fetch only specific fields, use select:

```bash
Book.select(:isbn, :out_of_print)
# OR
Book.select("isbn, out_of_print")

# Generated SQL:

SELECT isbn, out_of_print FROM books;
```

**Important Considerations**

- Fetching only specific columns initializes a model object with only those fields.

- Accessing unselected fields results in:

```bash
ActiveModel::MissingAttributeError: missing attribute '<attribute>' for Book
```

- The id field does not raise this error but is required for associations to work correctly.

**Using distinct for Unique Records**

- To fetch unique values for a specific field:

```bash
Customer.select(:last_name).distinct

# Generated SQL:

SELECT DISTINCT last_name FROM customers;
```

- To remove the uniqueness constraint:

```bash
query = Customer.select(:last_name).distinct
query.distinct(false) # Fetches all values, including duplicates
```

# 6. SQL LIMIT and OFFSET in ActiveRecord

**Applying LIMIT in ActiveRecord**

- `limit(n)`: Retrieves up to `n` records from the table.

```bash
Customer.limit(5)

# SQL Executed:

SELECT * FROM customers LIMIT 5;

# Returns the first 5 customers.
```

**Applying OFFSET in ActiveRecord**

- `offset(n)`: Skips the first `n` records before returning results.

```bash
Customer.limit(5).offset(30)

# SQL Executed:

SELECT * FROM customers LIMIT 5 OFFSET 30;
```

- Skips the first 30 records and returns the next 5.

- Use `limit` to control the number of records fetched.

- Use `offset` to paginate results efficiently.

# 7. SQL GROUP BY and HAVING in Rails Active Record

## 7.1 Using group Method

- The group method applies a `GROUP BY` clause to the SQL fired by the finder.

```bash
Order.select("created_at").group("created_at")

# Generates SQL:

SELECT created_at FROM orders GROUP BY created_at;

# Returns a single `Order` object for each unique `created_at` date.
```

## 7.2 Counting Grouped Items

- Use `.count` after `group` to get totals.

```bash
Order.group(:status).count

# Generates SQL:

SELECT COUNT(*) AS count_all, status AS status FROM orders GROUP BY status;

# Returns a hash:

{"being_packed"=>7, "shipped"=>12}
```

## 7.3 Using `HAVING` for Group Conditions

- The HAVING clause filters grouped results.

```bash
Order.select("created_at as ordered_date, sum(total) as total_price")
     .group("created_at")
     .having("sum(total) > ?", 200)

# Generates SQL:

SELECT created_at as ordered_date, sum(total) as total_price
FROM orders
GROUP BY created_at
HAVING sum(total) > 200;

# Returns orders grouped by date where total is greater than $200.
```

## 7.4 Accessing Grouped Data

```bash
big_orders = Order.select("created_at, sum(total) as total_price")
                  .group("created_at")
                  .having("sum(total) > ?", 200)
big_orders[0].total_price # Returns the total price of the first grouped order
```

# 8. Overriding Conditions

## 8.1 unscope

- The unscope method removes specific query conditions.

```bash
Book.where("id > 100").limit(20).order("id desc").unscope(:order)

# SQL Executed:

SELECT * FROM books WHERE id > 100 LIMIT 20
```

- Removing a specific `where` clause:

```bash
Book.where(id: 10, out_of_print: false).unscope(where: :id)

# SQL Executed:

SELECT books.* FROM books WHERE out_of_print = 0
```

- `unscope` affects merged relations:

```bash
Book.order("id desc").merge(Book.unscope(:order))

# SQL Executed:

SELECT books.* FROM books
```

## 8.2 only

- The `only` method keeps specified conditions and removes others.

```bash
Book.where("id > 10").limit(20).order("id desc").only(:order, :where)

# SQL Executed:

SELECT * FROM books WHERE id > 10 ORDER BY id DESC
```

## 8.3 reselect

- The `reselect` method overrides an existing `select` statement.

```bash
Book.select(:title, :isbn).reselect(:created_at)

# SQL Executed:

SELECT books.created_at FROM books
```

- Without `reselect`, adding another `select` appends to the selection:

```bash
Book.select(:title, :isbn).select(:created_at)

# SQL Executed:

SELECT books.title, books.isbn, books.created_at FROM books
```

## 8.4 reorder

- Overrides the default order specified in associations or queries.

```ruby
class Author < ApplicationRecord
  has_many :books, -> { order(year_published: :desc) }
end
```

```bash
Author.find(10).books.reorder("year_published ASC")
```

- SQL Output:

```bash
SELECT * FROM books WHERE author_id = 10 ORDER BY year_published ASC;
```

## 8.5 reverse_order


- Reverses the ordering clause if specified.

```bash
Book.where("author_id > 10").order(:year_published).reverse_order

# SQL Output:

SELECT * FROM books WHERE author_id > 10 ORDER BY year_published DESC;
```

- If no ordering clause is specified, it orders by the primary key in reverse order.

```bash
Book.where("author_id > 10").reverse_order

# SQL Output:

SELECT * FROM books WHERE author_id > 10 ORDER BY books.id DESC;
```

- Takes no arguments.

## 8.6 rewhere

Overrides an existing `where` condition instead of combining them with `AND`.

```bash
Book.where(out_of_print: true).rewhere(out_of_print: false)

# SQL Output:

SELECT * FROM books WHERE out_of_print = 0;
```

- Without `rewhere`, conditions are combined:

```bash
Book.where(out_of_print: true).where(out_of_print: false)

# SQL Output (Invalid Query):

SELECT * FROM books WHERE out_of_print = 1 AND out_of_print = 0;
```

## 8.7 regroup


- Overrides an existing `group` condition instead of combining them.

```bash
Book.group(:author).regroup(:id)

# SQL Output:

SELECT * FROM books GROUP BY id;
```

- Without `regroup`, conditions are combined:

```bash
Book.group(:author).group(:id)

# SQL Output:

SELECT * FROM books GROUP BY author, id;
```

# 9. `none` Method  

 - The `none` method returns a chainable relation with no records. Any subsequent conditions chained to this relation will continue generating empty results.  
 
```ruby
Book.none # Returns an empty Relation and fires no queries.
```
 
- Consider a scenario where a method or scope should always return a chainable relation, even if there are no results.
 
```ruby
class Book
  # Returns reviews if there are at least 5,
  # else returns an empty relation
  def highlighted_reviews
    if reviews.count > 5
      reviews
    else
      Review.none # Ensures a chainable empty result
    end
  end
end
```

### Querying the `highlighted_reviews` Method  

```ruby
Book.first.highlighted_reviews.average(:rating)
# Returns the average rating if there are at least 5 reviews.
# Otherwise, it returns nil without firing unnecessary queries.
```

## Key Takeaways  
- `none` ensures that methods return an ActiveRecord Relation instead of `nil`.  
- This is useful for maintaining consistent query chains.  
- Prevents unnecessary database queries when no results are expected.  

# 10. Readonly Objects in Active Record

- **Readonly Method**: 
  - Active Record provides the `readonly` method to explicitly prevent modification of any returned objects.
  - Any attempt to modify a readonly object will raise an `ActiveRecord::ReadOnlyRecord` exception.

  ```ruby
  customer = Customer.readonly.first
  customer.visits += 1
  customer.save # Raises an ActiveRecord::ReadOnlyRecord

- Once an object is set to `readonly`, it cannot be updated, and trying to do so (like calling `save`) will result in the `ActiveRecord::ReadOnlyRecord` exception.

# 11.  Locking Records for Update in Rails

Locking is useful for preventing race conditions when updating records in the database and ensuring atomic updates. Active Record provides two locking mechanisms:

- Optimistic Locking
- Pessimistic Locking

## 1. Optimistic Locking

Optimistic Locking allows multiple users to access the same record for edits, assuming minimal conflicts with the data. It checks if another process has made changes to a record since it was opened, and throws an `ActiveRecord::StaleObjectError` exception if that has occurred.

### Optimistic Locking Column

To use optimistic locking, the table needs to have a column called `lock_version` of type integer. Every time the record is updated, Active Record increments this `lock_version` column. If an update request is made with a lower value in the `lock_version` field, the update request will fail with an `ActiveRecord::StaleObjectError`.

**Example:**
```ruby
c1 = Customer.find(1)
c2 = Customer.find(1)

c1.first_name = "Sandra"
c1.save

c2.first_name = "Michael"
c2.save # Raises ActiveRecord::StaleObjectError
```

- You can handle the exception by rescuing it and applying the business logic to resolve the conflict.

**Disable Optimistic Locking**

- You can turn off optimistic locking by setting:

```ruby
ActiveRecord::Base.lock_optimistically = false
```

**Custom Locking Column**

- To override the default `lock_version` column name, you can use:

```ruby
class Customer < ApplicationRecord
  self.locking_column = :lock_customer_column
end
```