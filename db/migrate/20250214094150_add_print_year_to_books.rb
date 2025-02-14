class AddPrintYearToBooks < ActiveRecord::Migration[8.0]
  def change
    add_column :books, :print_year, :integer
  end
end
