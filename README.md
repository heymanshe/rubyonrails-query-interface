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

