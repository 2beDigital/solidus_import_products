# frozen_string_literal: true

Spree::ProductImport.settings = {
  num_prods_for_delayed: 20, # From this number of products, the process is executed in delayed_job. Under it is processed immediately.
  create_missing_taxonomies: true,
  create_missing_shipping_category: true,
  create_missing_tax_category: true,
  product_image_path: "#{Rails.root}/lib/etc/product_data/product-images/", # The location of images on disk
  log_to: File.join(Rails.root, '/log/', "import_products_#{Rails.env}.log"), # Where to log to
  destroy_original_products: false, # Disabled #Delete the products originally in the database after the import?
  create_variants: true, # Compares products and creates a variant if that product already exists.
  store_field: :store_code, # Which field of the column mappings contains either the store id or store code?
  transaction: true, # import product in a sql transaction so we can rollback when an exception is raised
  separator: "," # Default value for the admin form input
}
