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

## 11.1 Optimistic Locking

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

## 11.2 Pessimistic Locking

- Pessimistic Locking uses a locking mechanism provided by the database. The lock method obtains an exclusive lock on the selected rows. Pessimistic locking is typically used with transactions to prevent deadlock conditions.

```ruby
Book.transaction do
  book = Book.lock.first
  book.title = "Algorithms, second edition"
  book.save!
end
```

- This will generate the following SQL for MySQL:

```sql
BEGIN
SELECT * FROM books LIMIT 1 FOR UPDATE
UPDATE books SET updated_at = '2009-02-07 18:05:56', title = 'Algorithms, second edition' WHERE id = 1
COMMIT
```

**Using Raw SQL in Pessimistic Locking**

- You can pass raw SQL to the `lock` method for different types of locks. For example, in MySQL, you can use `LOCK IN SHARE MODE` to lock a record but still allow other queries to read it.

```ruby
Book.transaction do
  book = Book.lock("LOCK IN SHARE MODE").find(1)
  book.increment!(:views)
end
```

**Locking an Instance with a Block**

- If you already have an instance of the model, you can acquire the lock in one go using with_lock:

```ruby
book = Book.first
book.with_lock do
  # The block is executed within a transaction, and the book is locked
  book.increment!(:views)
end
```

# ActiveRecord Joins in Rails

## 12. Joining Tables
Active Record provides two methods for specifying JOIN clauses in SQL queries: `joins` and `left_outer_joins`. 
- `joins` is used for INNER JOINs or custom queries.
- `left_outer_joins` is used for LEFT OUTER JOIN queries.

---

## 12.1 `joins`
The `joins` method can be used in several ways:

### 12.1.1 Using a String SQL Fragment
You can directly supply a raw SQL string specifying the JOIN clause:
```ruby
Author.joins("INNER JOIN books ON books.author_id = authors.id AND books.out_of_print = FALSE")
```
This will generate the following SQL:
```sql
SELECT authors.* FROM authors INNER JOIN books ON books.author_id = authors.id AND books.out_of_print = FALSE
```

### 12.1.2 Using Array/Hash of Named Associations
You can use model associations as a shortcut for JOIN clauses.

#### 12.1.2.1 Joining a Single Association
To join a single association:
```ruby
Book.joins(:reviews)
```
This produces:
```sql
SELECT books.* FROM books INNER JOIN reviews ON reviews.book_id = books.id
```

#### 12.1.2.2 Joining Multiple Associations
To join multiple associations:
```ruby
Book.joins(:author, :reviews)
```
This produces:
```sql
SELECT books.* FROM books
  INNER JOIN authors ON authors.id = books.author_id
  INNER JOIN reviews ON reviews.book_id = books.id
```

#### 12.1.2.3 Joining Nested Associations (Single Level)
For nested associations:
```ruby
Book.joins(reviews: :customer)
```
This produces:
```sql
SELECT books.* FROM books
  INNER JOIN reviews ON reviews.book_id = books.id
  INNER JOIN customers ON customers.id = reviews.customer_id
```

#### 12.1.2.4 Joining Nested Associations (Multiple Levels)
For multiple nested associations:
```ruby
Author.joins(books: [{ reviews: { customer: :orders } }, :supplier])
```
This produces:
```sql
SELECT authors.* FROM authors
  INNER JOIN books ON books.author_id = authors.id
  INNER JOIN reviews ON reviews.book_id = books.id
  INNER JOIN customers ON customers.id = reviews.customer_id
  INNER JOIN orders ON orders.customer_id = customers.id
  INNER JOIN suppliers ON suppliers.id = books.supplier_id
```

### 12.1.3 Specifying Conditions on Joined Tables
You can specify conditions on the joined tables using `where` clauses.

#### Example:
```ruby
time_range = (Time.now.midnight - 1.day)..Time.now.midnight
Customer.joins(:orders).where("orders.created_at" => time_range).distinct
```
This will find all customers with orders created yesterday.

#### Cleaner Syntax:
```ruby
time_range = (Time.now.midnight - 1.day)..Time.now.midnight
Customer.joins(:orders).where(orders: { created_at: time_range }).distinct
```

#### Using Named Scopes:
First, define a scope in the `Order` model:
```ruby
class Order < ApplicationRecord
  belongs_to :customer

  scope :created_in_time_range, ->(time_range) { where(created_at: time_range) }
end
```

Then, use the `merge` method to apply the scope:
```ruby
time_range = (Time.now.midnight - 1.day)..Time.now.midnight
Customer.joins(:orders).merge(Order.created_in_time_range(time_range)).distinct
```
This will find all customers with orders created yesterday.


## 12.2 `left_outer_joins`

- The `left_outer_joins` method allows you to select records, regardless of whether they have associated records.

```ruby
Customer.left_outer_joins(:reviews).distinct.select("customers.*, COUNT(reviews.*) AS reviews_count").group("customers.id")
```

```sql
SELECT DISTINCT customers.*, COUNT(reviews.*) AS reviews_count
FROM customers
LEFT OUTER JOIN reviews ON reviews.customer_id = customers.id
GROUP BY customers.id
```

- This query returns all customers with their review count, whether or not they have any reviews.

## 12.3 `where.associated` and `where.missing`

- These methods allow you to filter records based on the presence or absence of an association.

### `where.associated`

- This method selects records that have an associated record.

```ruby
Customer.where.associated(:reviews)
```

```sql
SELECT customers.*
FROM customers
INNER JOIN reviews ON reviews.customer_id = customers.id
WHERE reviews.id IS NOT NULL
```

- This query returns all customers that have made at least one review.

### `where.missing`

- This method selects records that are missing an associated record.

```ruby
Customer.where.missing(:reviews)
```

```sql
SELECT customers.*
FROM customers
LEFT OUTER JOIN reviews ON reviews.customer_id = customers.id
WHERE reviews.id IS NULL
```

- This query returns all customers that have not made any reviews.


# 13 Eager Loading Associations

- Eager loading is the mechanism for loading the associated records of the objects returned by `Model.find` using as few queries as possible.

## 13.1 N + 1 Queries Problem

- The following code finds 10 books and prints their authors' last names:

```ruby
books = Book.limit(10)

books.each do |book|
  puts book.author.last_name
end
```

- While the code seems fine, the problem lies within the total number of queries executed:
  - 1 query to find 10 books
  - 10 queries to load the authors for each of the books

- In total, this results in 11 queries being executed.

### 13.1.1 Solution to N + 1 Queries Problem

- To solve the `N + 1` queries problem, Active Record lets you specify in advance all the associations that need to be loaded.

- The methods to prevent `N + 1` queries are:

- `includes`
- `preload`
- `eager_load`

## 13.2 Includes

- The `includes` method in Active Record is used to eager load associations, ensuring that all specified associations are loaded using the minimum possible number of queries.

```ruby
books = Book.includes(:author).limit(10)
books.each do |book|
  puts book.author.last_name
end
```

- This code executes 2 queries instead of 11 queries:

```bash
SELECT books.* FROM books LIMIT 10
SELECT authors.* FROM authors WHERE authors.id IN (1, 2, 3, 4, 5, 6, 7, 8, 9, 10)
```

### 13.2.1 Eager Loading Multiple Associations

- Active Record allows you to eager load multiple associations using:

  - Array of associations
  - Hash of associations
  - Nested hash of associations

#### 13.2.1.1 Array of Multiple Associations:

```ruby
Customer.includes(:orders, :reviews)
```

- This loads all customers with their associated orders and reviews.

#### 13.2.1.2 Nested Associations Hash:

```ruby
Customer.includes(orders: { books: [:supplier, :author] }).find(1)
```

- This finds the customer with ID 1 and eager loads:

  - Associated orders for the customer
  - Books for each order
  - Authors and suppliers for each book

### 13.2.2 Specifying Conditions on Eager Loaded Associations

- Although conditions can be specified on eager-loaded associations using where, it's recommended to use joins for conditions.

```ruby
Author.includes(:books).where(books: { out_of_print: true })
```

- This generates a LEFT OUTER JOIN query:

```sql
SELECT authors.id AS t0_r0, ... books.updated_at AS t1_r5 
FROM authors 
LEFT OUTER JOIN books ON books.author_id = authors.id 
WHERE (books.out_of_print = 1)
```

**Using where with SQL Fragments**:

- If you need to use raw SQL fragments with includes, you can use references:

```ruby
Author.includes(:books).where("books.out_of_print = true").references(:books)
```

- This forces the join condition to be applied to the correct table.


## 13.3 preload

- `preload` loads each specified association using **one query per association**.
- Resolves the N + 1 queries problem by executing **just 2 queries**.

```bash
Book.preload(:author).limit(10)

# SQL
 
SELECT books.* FROM books LIMIT 10

SELECT authors.* FROM authors WHERE authors.id IN (1,2,3,4,5,6,7,8,9,10)
```

- Unlike `includes`, `preload` does not allow specifying conditions for preloaded associations.
- Good for cases where you don't need to filter or join data between the parent and child model.

## 13.4 eager_load

- `eager_load` loads all specified associations using **a LEFT OUTER JOIN**.
- Resolves the N + 1 queries problem by executing **just 1 query**.

```bash
Book.eager_load(:author).limit(10)

# SQL 

SELECT books.id, books.title, ... FROM books LEFT OUTER JOIN authors ON authors.id = books.author_id LIMIT 10
```

- Like `includes`, `eager_load` allows specifying conditions for eager-loaded associations.
- Ideal for when you need to filter or join data from the parent and child models.

## 13.5 Strict Loading in Rails

- Strict Loading in Rails helps to avoid lazy loading and N + 1 query issues. It ensures that no associations are lazily loaded unless explicitly allowed.

- Eager loading can prevent N + 1 queries but lazy loading might still occur for some associations.

- To prevent lazy loading, enable `strict_loading`.

- When `strict_loading` is enabled, an `ActiveRecord::StrictLoadingViolationError` is raised if a lazy-loaded association is accessed.

```ruby
user = User.strict_loading.first
user.address.city # raises ActiveRecord::StrictLoadingViolationError
user.comments.to_a # raises ActiveRecord::StrictLoadingViolationError
```
- To enable strict loading by default for all relations, set config.active_record.strict_loading_by_default = true.
- To log violations instead of raising errors, set config.active_record.action_on_strict_loading_violation = :log.

## 13.6 strict_loading!

- `strict_loading!` can be called on a record to enable strict loading.

- This method raises an error if a lazy-loaded association is accessed after the record is flagged with strict_loading!.

```bash
user = User.first
user.strict_loading!
user.address.city # raises ActiveRecord::StrictLoadingViolationError
user.comments.to_a # raises ActiveRecord::StrictLoadingViolationError
```

- `strict_loading!` accepts a `:mode argument:`

- `:n_plus_one_only` will raise an error only for lazy-loaded associations that would lead to an `N + 1` query.

```ruby
user.strict_loading!(mode: :n_plus_one_only)
user.address.city # works
user.comments.first.likes.to_a # raises ActiveRecord::StrictLoadingViolationError
```

## 13.7 strict_loading option on an association

- You can enable strict loading for a specific association by passing `strict_loading: true`.

```bash
class Author < ApplicationRecord
  has_many :books, strict_loading: true
end
```

- This ensures that any lazy loading of the books association will raise an error.

# 14. Scopes

- Scopes in Rails allow you to define reusable queries that can be called as methods on models or associations. Scopes return an `ActiveRecord::Relation`, enabling method chaining.

- Define a scope using the `scope` method inside a model class:

```ruby
class Book < ApplicationRecord
  scope :out_of_print, -> { where(out_of_print: true) }
end
```

- Call the scope directly on the model or an association:

```ruby
Book.out_of_print # Returns all out-of-print books

author = Author.first
author.books.out_of_print # Returns all out-of-print books by the author
```

- Scopes can be combined for more complex queries:

```ruby
class Book < ApplicationRecord
  scope :out_of_print, -> { where(out_of_print: true) }
  scope :out_of_print_and_expensive, -> { out_of_print.where("price > 500") }
end
```

## 14.1 Passing Arguments to Scopes

- Scopes can accept parameters:

```ruby
class Book < ApplicationRecord
  scope :costs_more_than, ->(amount) { where("price > ?", amount) }
end
```

### Calling a Scope with Arguments
```ruby
Book.costs_more_than(100.10)
```

## Alternative Using Class Methods
Scopes can be replaced with class methods:

```ruby
class Book < ApplicationRecord
  def self.costs_more_than(amount)
    where("price > ?", amount)
  end
end
```

- Class methods work similarly on associations:

```ruby
author.books.costs_more_than(100.10)
```

## 14.2 Using Conditionals in Scopes

- Scopes can use conditionals:

```ruby
class Order < ApplicationRecord
  scope :created_before, ->(time) { where(created_at: ...time) if time.present? }
end
```

- Scopes behave similarly to class methods:

```ruby
class Order < ApplicationRecord
  def self.created_before(time)
    where(created_at: ...time) if time.present?
  end
end
```

- A scope always returns an `ActiveRecord::Relation`, even if the conditional is `false`.

- A class method can return `nil`, potentially causing `NoMethodError` when chaining methods.

## 14.3 Applying a Default Scope

- A default_scope applies a scope to all queries on the model:

```ruby
class Book < ApplicationRecord
  default_scope { where(out_of_print: false) }
end
```

- The SQL query will always include the condition:

```bash
SELECT * FROM books WHERE (out_of_print = false)
```

- Alternative way using a class method:

```ruby
class Book < ApplicationRecord
  def self.default_scope
    # Should return an ActiveRecord::Relation.
  end
end
```

#### Effects of `Default Scope`:

- Applied when creating a new record (`Book.new` includes default scope attributes).

- Not applied when updating records.

**Caution**: Default scope using array format will not assign attributes correctly.

## 14.4 Merging of Scopes

- Scopes are merged using `AND` conditions:

```ruby
class Book < ApplicationRecord
  scope :in_print, -> { where(out_of_print: false) }
  scope :out_of_print, -> { where(out_of_print: true) }
  scope :recent, -> { where(year_published: 50.years.ago.year..) }
  scope :old, -> { where(year_published: ...50.years.ago.year) }
end

SELECT books.* FROM books WHERE books.out_of_print = 'true' AND books.year_published < 1969
```

- `where` and `scope` conditions combine automatically:

```bash
SELECT books.* FROM books WHERE books.out_of_print = 'false' AND books.price < 100
```

- To override conflicting where conditions, use merge:

```bash
Book.in_print.merge(Book.out_of_print)

SELECT books.* FROM books WHERE books.out_of_print = true
```

- Effect of `Default` Scope on Scopes and Queries:

```ruby
class Book < ApplicationRecord
  default_scope { where(year_published: 50.years.ago.year..) }
end

SELECT books.* FROM books WHERE (year_published >= 1969)
```

## 14.5 Removing All Scoping

- Use unscoped to remove all applied scopes:

```bash
Book.unscoped.load

SELECT books.* FROM books
```

- unscoped can be used within a block:

```bash
Book.unscoped { Book.out_of_print }

SELECT books.* FROM books WHERE books.out_of_print = true
```

# 15. Dynamic Finders

- Active Record automatically provides finder methods for each field in a model.

- Example: If `first_name` is a field in Customer, you can use:

```bash
Customer.find_by_first_name("Ryan")
```

- If a field like locked exists, the method find_by_locked is available.

- Adding `!` to the method raises `ActiveRecord::RecordNotFound` if no record is found:

```bash
Customer.find_by_first_name!("Ryan")
```

- To find records based on multiple fields, use "and":

```bash
Customer.find_by_first_name_and_orders_count("Ryan", 5)
```

# 16. Enums

- Enums allow defining an array of values for an attribute, stored as integers in the database.

```ruby
class Order < ApplicationRecord
  enum :status, [:shipped, :being_packaged, :complete, :cancelled]
end
```

- Scopes created automatically:

```bash
Order.shipped       # Finds all orders with status == :shipped
Order.not_shipped   # Finds all orders with status != :shipped
```

- Instance methods for querying enum values:

```bash
order = Order.shipped.first
order.shipped?  # => true
order.complete? # => false
```

- Instance methods to update and check status:

```bash
order = Order.first
order.shipped!
# Updates status to :shipped and returns true if successful
```

- Enums make it easier to manage status-like attributes with meaningful names instead of integers.


# 17. Understanding Method Chaining

- Method Chaining in Active Record allows combining multiple methods in a concise way. It works when a method returns an `ActiveRecord::Relation` object, enabling further operations like filtering and joining tables. Queries are only executed when data is actually needed.

### Key Points

- `Chaining Active Record Methods`: Methods like all, where, and joins return an ActiveRecord::Relation, allowing chaining.

- `Execution of Queries`: Queries are not executed immediately but only when data is required.

- `Methods Returning Single Objects`: Methods like find_by must be at the end of the chain since they return a single object.


## 17.1 Retrieving Filtered Data from Multiple Tables

```bash
Customer
  .select("customers.id, customers.last_name, reviews.body")
  .joins(:reviews)
  .where("reviews.created_at > ?", 1.week.ago)
```

- Generated SQL Query:

```bash
SELECT customers.id, customers.last_name, reviews.body
FROM customers
INNER JOIN reviews
  ON reviews.customer_id = customers.id
WHERE (reviews.created_at > 'YYYY-MM-DD')
```

## 17.2 Retrieving Specific Data from Multiple Tables

```bash
Book
  .select("books.id, books.title, authors.first_name")
  .joins(:author)
  .find_by(title: "Abstraction and Specification in Program Development")
```

- Generated SQL Query:

```bash
SELECT books.id, books.title, authors.first_name
FROM books
INNER JOIN authors
  ON authors.id = books.author_id
WHERE books.title = $1 [["title", "Abstraction and Specification in Program Development"]]
LIMIT 1
```

**Note**: `find_by` retrieves only the first matching record (LIMIT 1).

# 18. Finding or Creating Records 

## 18.1 find_or_create_by

- Checks whether a record with the specified attributes exists.

- If it does not exist, it calls create to insert a new record.

```bash
Customer.find_or_create_by(first_name: 'Andy')
```

- Generates the following SQL:

```bash
SELECT * FROM customers WHERE (customers.first_name = 'Andy') LIMIT 1;
BEGIN;
INSERT INTO customers (created_at, first_name, locked, orders_count, updated_at)
VALUES ('2011-08-30 05:22:57', 'Andy', 1, NULL, '2011-08-30 05:22:57');
COMMIT;
```

- Returns either the existing record or the newly created record.

- If validations fail, the new record will not be saved.

### Setting Default Attributes on Creation

- Use `create_with`:

```bash
Customer.create_with(locked: false).find_or_create_by(first_name: "Andy")
```

- Or use a block (executed only if the record is created):

```bash
Customer.find_or_create_by(first_name: "Andy") do |c|
  c.locked = false
end
```

## 18.2 find_or_create_by!

- Similar to find_or_create_by but raises an exception if the new record is invalid.

```bash
Customer.find_or_create_by!(first_name: 'Andy')
```

- If `orders_count` validation is added:

```bash
validates :orders_count, presence: true
```

- Running the above will raise an error:

```bash
ActiveRecord::RecordInvalid: Validation failed: Orders count can't be blank
```

## 18.3 find_or_initialize_by

- Works like `find_or_create_by` but calls new instead of create.

- A new model instance is created in memory but not saved to the database.

```bash
nina = Customer.find_or_initialize_by(first_name: 'Nina')
```

- The record is not yet persisted:

```bash
nina.persisted? # => false
nina.new_record? # => true
```

- Generated SQL:

```bash
SELECT * FROM customers WHERE (customers.first_name = 'Nina') LIMIT 1;
```

- Save it explicitly:

```bash
nina.save # => true
```

# 19. SQL Finding Methods in ActiveRecord

## 19.1 find_by_sql

- Allows executing custom SQL queries.

- Returns an array of ActiveRecord objects.

```bash
Customer.find_by_sql("SELECT * FROM customers INNER JOIN orders ON customers.id = orders.customer_id ORDER BY customers.created_at DESC")
```

## 19.2 select_all

- Similar to `find_by_sql` but does not instantiate ActiveRecord objects.

- Returns an `ActiveRecord::Result` object.

```bash
Customer.lease_connection.select_all("SELECT first_name, created_at FROM customers WHERE id = '1'").to_a
```

- Output is an array of hashes.

## 19.3 pluck

- Retrieves values directly as an array without creating ActiveRecord objects.

- Efficient for fetching column values.

```bash
Book.where(out_of_print: true).pluck(:id)
Order.distinct.pluck(:status)
Customer.pluck(:id, :first_name)
```

- More efficient than:

```bash
Customer.select(:id).map(&:id)
```

- Cannot be chained further (e.g., `pluck(:first_name).limit(1)` is invalid).

## 19.4 pick

- Fetches a single value from the first row.

- Equivalent to `relation.limit(1).pluck(*column_names).first`.

```bash
Customer.where(id: 1).pick(:id)
```

