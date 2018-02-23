module SolidusImportProducts
  class ProcessRow
    attr_accessor :product_imports, :logger, :row, :col, :product_information, :variant_field, :skus_of_products_before_import

    def initialize(args = { product_imports: nil, row: nil, col: nil, variant_field: nil, skus_of_products_before_import: nil })
      self.product_imports = args[:product_imports]
      self.row = args[:row]
      self.col = args[:col]
      self.variant_field = args[:variant_field]
      self.skus_of_products_before_import = args[:skus_of_products_before_import]
      self.logger = SolidusImportProducts::Logger.instance
      self.product_information = {}
    end

    def self.call(options = {})
      new(options).call
    end

    def call
      extract_product_information
      logger.log(product_information.to_s, :debug)

      variant_column = col[variant_field]
      product = Spree::Product.find_by(variant_field.to_s => row[variant_column])

      unless product
        if skus_of_products_before_import.include?(product_information[:sku])
          raise SolidusImportProducts::Exception::ProductError, "SKU #{product_information[:sku]} exists, but #{variant_field}: #{row[variant_column]} not exists!! "
        end
        product = Spree::Product.new
      end

      unless product_imports.product?(product)
        create_or_update_product(product)
        product_imports.add_product(product)
      end

      SolidusImportProducts::CreateVariant.call(product: product, product_information: product_information)
    end

    private

    def create_or_update_product(product)
      properties_hash = SolidusImportProducts::UpdateProduct.call(product: product, product_information: product_information)
      SolidusImportProducts::SaveProduct.call(product: product, product_information: product_information)
      SolidusImportProducts::SaveProperties.call(product: product, properties_hash: properties_hash)
    end

    def extract_product_information
      col.each do |key, value|
        row[value].try :strip!
        product_information[key] = row[value]
      end

      product_information_default_values
    end

    def product_information_default_values
      product_information[:available_on] = Time.zone.today - 1.day if product_information[:available_on].nil?

      if product_information[:shipping_category_id].nil?
        sc = Spree::ShippingCategory.first
        product_information[:shipping_category_id] = sc.id unless sc.nil?
      end

      product_information[:retail_only] = 0 if product_information[:retail_only].nil?
    end

  end
end
