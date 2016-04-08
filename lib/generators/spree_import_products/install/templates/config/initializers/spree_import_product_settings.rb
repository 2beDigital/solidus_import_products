require 'active_job'
ActiveJob::Base.queue_adapter = :delayed_job
Delayed::Worker.backend = :active_record
Delayed::Worker.sleep_delay = 10
# Rails 4.1
Delayed::Worker.destroy_failed_jobs = true
# Rails 4.2
#Delayed::Job.destroy_failed_jobs = false
# This file is the thing you have to config to match your application

Spree::ProductImport.settings = {
    :column_mappings => { #Change these for manual mapping of product fields to the CSV file
                          :sku => 0,
                          :name => 1,
                          :master_price => 2,
                          :cost_price => 3,
                          :weight => 4,
                          :height => 5,
                          :width => 6,
                          :depth => 7,
                          :image_main => 8,
                          :image_2 => 9,
                          :image_3 => 10,
                          :image_4 => 11,
                          :description => 12,
                          :category => 13
    },
    :num_prods_for_delayed => 20, #From this number of products, the process is executed in delayed_job. Under it is processed immediately.
    :create_missing_taxonomies => true,
    :taxonomy_fields => [:taxonomies], #Fields that should automatically be parsed for taxons to associate
    :image_fields_products => [:image_product, :image_product_2, :image_product_3, :image_product_4], #Image fields that should be parsed for image locations of products
    :image_fields_variants => [:image_variant, :image_variant_2, :image_variant_3, :image_variant_4], #Image fields that should be parsed for image locations of variants
    :image_text_products => :alt_product, #Field that contains alt text for images of product.
    :image_text_variants => :alt_variant, #Field that contains alt text for images of variant.
    :product_image_path => "#{Rails.root}/lib/etc/product_data/product-images/", #The location of images on disk
    :rows_to_skip => 1, #If your CSV file will have headers, this field changes how many rows the reader will skip
    :log_to => File.join(Rails.root, '/log/', "import_products_#{Rails.env}.log"), #Where to log to
    :destroy_original_products => false, #Disabled #Delete the products originally in the database after the import?
    :first_row_is_headings => true, #Reads column names from first row if set to true.
    :create_variants => true, #Compares products and creates a variant if that product already exists.
    :price_field => :price, #Field that contains the price of a product. Is required in new products.
    :variant_comparator_field => :slug, #Which product field to detect duplicates on
    :variant_comparator_field_i18n => :slugi18n, #CSV column with translation of variant_comparator_field. Not used yet.
    :multi_domain_importing => false, #If Spree's multi_domain extension is installed, associates products with store.
    :store_field => :store_code, #Which field of the column mappings contains either the store id or store code?
    :transaction => true #import product in a sql transaction so we can rollback when an exception is raised
}