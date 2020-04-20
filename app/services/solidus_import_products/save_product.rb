# frozen_string_literal: true

module SolidusImportProducts
  class SaveProduct
    attr_accessor :product, :product_information, :logger, :image_path

    include SolidusImportProducts::ImportHelper

    def self.call(options = {})
      new.call(options)
    end

    def call(args = { product: nil, product_information: nil, image_path: nil })
      self.logger = SolidusImportProducts::Logger.instance
      self.product_information = args[:product_information]
      self.product = args[:product]
      self.image_path = args[:image_path]

      logger.log("SAVE PRODUCT: #{product.inspect}", :debug)

      unless product.valid?
        msg = "A product could not be imported - here is the information we have:\n" \
              "#{product_information}, #{product.inspect} #{product.errors.full_messages.join(', ')}"
        logger.log(msg, :error)
        raise SolidusImportProducts::Exception::ProductError, msg
      end

      product.save

      # Associate our new product with any taxonomies that we need to worry about
      if product_information[:attributes].key?(:taxonomies) && product_information[:attributes][:taxonomies]
        associate_product_with_taxon(product, product_information[:attributes][:taxonomies], true)
      end

      # Finally, attach any images that have been specified
      product_information[:images].each do |filename|
        find_and_attach_image_to(product, filename, image_path)
      end

      logger.log("#{product.name} successfully imported.\n")
      true
    end
  end
end
