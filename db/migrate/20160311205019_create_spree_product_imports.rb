class CreateSpreeProductImports < ActiveRecord::Migration
  def self.up
    create_table :spree_product_imports do |t|
      t.string :data_file_file_name
      t.string :data_file_content_type
      t.integer :data_file_file_size
      t.datetime :data_file_updated_at
      t.string :state
      t.text :product_ids
      t.datetime :completed_at
      t.datetime :failed_at
      t.text :error_message
      t.integer :created_by
      t.timestamps
    end
  end

  def self.down
    drop_table :spree_product_imports
  end
end
