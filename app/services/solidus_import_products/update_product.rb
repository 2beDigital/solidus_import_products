# frozen_string_literal: true

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

      product_information.each do |field, value|
        if field == :product_properties
          value.each { |prop_field, prop_value| properties_hash[prop_field] = prop_value }
        elsif field == :attributes
          value.each { |attr_field, attr_value| product.send("#{attr_field}=", attr_value) if product.respond_to?("#{attr_field}=") }
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
