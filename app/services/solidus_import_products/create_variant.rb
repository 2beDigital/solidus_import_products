# frozen_string_literal: true

module SolidusImportProducts
  # CreateVariant
  # This method assumes that some form of checking has already been done to
  # make sure that we do actually want to create a variant.
  # It performs a similar task to a product, but it also must pick up on
  # size/color options
  class CreateVariant
    attr_accessor :product, :variant, :product_information, :logger, :image_path

    include SolidusImportProducts::ImportHelper

    def self.call(options = {})
      new.call(options)
    end

    def call(args = { product: nil, product_information: nil, image_path: nil })
      self.logger = SolidusImportProducts::Logger.instance
      self.product_information = args[:product_information]
      self.product = args[:product]
      self.image_path = args[:image_path]

      return if product_information.nil?

      load_or_initialize_variant

      product_information.each do |field, value|
        if field == :variant_options
          value.each { |variant_field, variant_value| options(variant_field, variant_value) }
        elsif field == :attributes
          value.each { |attr_field, attr_value| variant.send("#{attr_field}=", attr_value) if variant.respond_to?("#{attr_field}=") }
        end
      end

      begin
        variant.save

        product_information[:variant_images].each do |filename|
          find_and_attach_image_to(variant, filename, image_path)
        end

        stock_items
        logger.log("Variant of SKU #{variant.sku} successfully imported.\n", :debug)
      rescue StandardError => e
        message = "A variant could not be imported - here is the information we have:\n"
        message += "#{product_information}, #{variant.errors.full_messages.join(', ')}\n"
        message += e.message.to_s
        logger.log(message, :error)
        raise SolidusImportProducts::Exception::VariantError, message
      end
      variant
    end

    private

    def load_or_initialize_variant
      self.variant = Spree::Variant.find_by(sku: product_information[:attributes][:sku])

      if variant
        if variant.product != product
          raise SolidusImportProducts::Exception::SkuError,
                "SKU #{product_information[:attributes][:sku]} should belongs to #{product.inspect} but was #{variant.product.inspect}"
        end
        product_information[:attributes].delete(:id)
      else
        self.variant = product.variants.new(sku: product_information[:attributes][:sku], id: product_information[:attributes][:id])
      end
    end

    def options(field, value)
      return unless value

      option_type = get_or_create_option_type(field)
      option_value = get_or_create_option_value(option_type, value)

      product.option_types << option_type unless product.option_types.include?(option_type)

      variant.option_values << option_value unless variant.option_values.include?(option_value)
    end

    def get_or_create_option_type(field)
      Spree::OptionType.where('name = :field or presentation = :field', field: field.to_s).first ||
        Spree::OptionType.create(name: field, presentation: field.to_s.titleize)
    end

    def get_or_create_option_value(option_type, value)
      option_type.option_values.where('name = :value or presentation = :value', value: value).first ||
        option_type.option_values.create(presentation: value, name: value.titleize)
    end

    def attach_image
      Spree::ProductImport.settings[:image_fields_variants].each do |field|

      end
    end

    def stock_items
      source_location = Spree::StockLocation.find_by(default: true)
      unless source_location
        logger.log('Seems that there are no SourceLocation set right?, so stock will not set.', :warn) if product_information[:attributes][:stock] || product_information[:attributes][:backorderable]
        return
      end
      logger.log("SourceLocation: #{source_location.inspect}", :debug)

      stock_item = variant.stock_items.where(stock_location_id: source_location.id).first_or_initialize

      stock_item.send('backorderable=', product_information[:attributes][:backorderable]) if product_information[:attributes].key?(:backorderable) && stock_item.respond_to?('backorderable=')

      stock_item.set_count_on_hand(product_information[:attributes][:stock]) if product_information[:attributes][:stock]
    end
  end
end
