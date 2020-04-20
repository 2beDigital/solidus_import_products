# frozen_string_literal: true

FactoryBot.define do
  factory :product_import, class: Spree::ProductImport do
    data_file { File.new(File.join(File.dirname(__FILE__), '../../../spec', 'fixtures', 'valid.csv')) }
    compress_image_file { File.new(File.join(File.dirname(__FILE__), '../../../spec', 'fixtures', 'images.zip')) }
    association :user, factory: :admin_user
  end

  factory :full_product_import, parent: :product_import do
    data_file { File.new(File.join(File.dirname(__FILE__), '../../../spec', 'fixtures', 'valid_full.csv')) }
    compress_image_file { File.new(File.join(File.dirname(__FILE__), '../../../spec', 'fixtures', 'images.zip')) }
  end

  factory :invalid_product_import, parent: :product_import do
    data_file { File.new(File.join(File.dirname(__FILE__), '../../../spec', 'fixtures', 'invalid.csv')) }
    compress_image_file { File.new(File.join(File.dirname(__FILE__), '../../../spec', 'fixtures', 'images.zip')) }
  end

  factory :product_import_with_properties, parent: :product_import do
    data_file { File.new(File.join(File.dirname(__FILE__), '../../../spec', 'fixtures', 'products_with_properties.csv')) }
    compress_image_file { File.new(File.join(File.dirname(__FILE__), '../../../spec', 'fixtures', 'images.zip')) }
  end
end
