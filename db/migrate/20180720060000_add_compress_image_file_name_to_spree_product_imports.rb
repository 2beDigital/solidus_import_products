# frozen_string_literal: true

class AddCompressImageFileNameToSpreeProductImports < SolidusSupport::Migration[4.2]
  def change
    add_column :spree_product_imports, :compress_image_file_file_name, :string
    add_column :spree_product_imports, :compress_image_file_content_type, :string
    add_column :spree_product_imports, :compress_image_file_file_size, :integer
    add_column :spree_product_imports, :compress_image_file_updated_at, :datetime
  end
end
