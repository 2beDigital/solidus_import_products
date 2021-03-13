# frozen_string_literal: true

class AddEncodingAndSeparatorToSpreeProductImports < SolidusSupport::Migration[4.2]
  def change
    add_column :spree_product_imports, :separatorChar, :string
    add_column :spree_product_imports, :encoding_csv, :string
    add_column :spree_product_imports, :quoteChar, :string
  end
end
