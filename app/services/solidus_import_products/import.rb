# frozen_string_literal: true

module SolidusImportProducts
  class Import
    attr_accessor :product_imports, :logger

    def initialize(args = { product_imports: nil })
      self.product_imports = args[:product_imports]
      self.logger = SolidusImportProducts::Logger.instance
    end

    def self.call(options = {})
      new(options).call
    end

    def call
      skus_of_products_before_import = Spree::Product.all.map(&:sku)
      parser = product_imports.parse
      image_path = product_imports.unzip
      col = parser.column_mappings

      product_imports.start
      ActiveRecord::Base.transaction do
        parser.data_rows.each do |row|
          SolidusImportProducts::ProcessRow.call(
            parser: parser,
            product_imports: product_imports,
            row: row,
            col: col,
            skus_of_products_before_import: skus_of_products_before_import,
            image_path: image_path
          )
        end
      end

      product_imports.complete
      product_imports.destroy_data_uploaded
    rescue StandardError => se
      product_imports.failure!
      product_imports.destroy_data_uploaded
      raise se
    end
  end
end
