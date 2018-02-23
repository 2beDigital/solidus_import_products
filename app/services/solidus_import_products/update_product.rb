module SolidusImportProducts
  class UpdateProduct
    attr_accessor :product, :product_information, :logger

    include SolidusImportProducts::ImportHelper

    def self.call(options = {})
      new.call(options)
    end

    def call(args = { product: nil, product_information: nil })
      self.logger = SolidusImportProducts::Logger.instance
      self.product_information = args[:product_information]
      self.product = args[:product]

      logger.log("UPDATE PRODUCT: #{product.inspect} #{product_information.inspect}", :debug)

      product.update_attribute(:deleted_at, nil) if product.deleted_at
      product.variants.each { |variant| variant.update_attribute(:deleted_at, nil) }

      properties_hash = {}

      # Array of special fields. Prevent adding them to properties.
      special_fields = Spree::ProductImport.settings.values_at(
        :image_fields,
        :taxonomy_fields,
        :store_field,
        :variant_comparator_field
      ).flatten.map(&:to_s)

      product_information.each do |field, value|
        if field.to_s.eql?('price')
          product.price = convert_to_price(value)
        elsif product.respond_to?("#{field}=")
          product.send("#{field}=", value)
        elsif !special_fields.include?(field.to_s) && (property = Spree::Property.where('lower(name) = ?', field).first)
          properties_hash[property] = value
        end
      end

      setup_shipping_category(product) unless product.shipping_category

      properties_hash
    end

    private

    def setup_shipping_category(product)
      unless Spree::ShippingCategory.first
        Spree::ShippingCategory.find_or_create_by(name: 'Default')
      end
      product.shipping_category = Spree::ShippingCategory.first
    end

  end
end
