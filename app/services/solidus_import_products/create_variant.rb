module SolidusImportProducts
  # CreateVariant
  # This method assumes that some form of checking has already been done to
  # make sure that we do actually want to create a variant.
  # It performs a similar task to a product, but it also must pick up on
  # size/color options
  class CreateVariant
    attr_accessor :product, :variant, :product_information, :logger

    include SolidusImportProducts::ImportHelper

    def self.call(options = {})
      new.call(options)
    end

    def call(args = { product: nil, product_information: nil })
      self.logger = SolidusImportProducts::Logger.instance
      self.product_information = args[:product_information]
      self.product = args[:product]
      return if product_information.nil?

      load_or_initialize_variant

      product_information.each do |field, value|
        if field.to_s.eql?('price')
          variant.price = convert_to_price(value)
        elsif variant.respond_to?("#{field}=")
          variant.send("#{field}=", value)
        elsif SolidusImportProducts::Parser::NON_VARIANT_OPTION_FIELDS.include?(field.to_s)
          next
        end
        options(field, value)
      end

      begin
        variant.save
        attach_image
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
      self.variant = Spree::Variant.find_by(sku: product_information[:sku])

      if variant
        if variant.product != product
          raise SolidusImportProducts::Exception::SkuError,
                "SKU #{product_information[:sku]} should belongs to #{product.inspect} but was #{variant.product.inspect}"
        end
        product_information.delete(:id)
      else
        self.variant = product.variants.new(sku: product_information[:sku], id: product_information[:id])
      end
    end

    def options(field, value)
      return unless value
      return if SolidusImportProducts::Parser.variant_option_field?(field)

      option_type = get_or_create_option_type(field)
      option_value = get_or_create_option_value(option_type, value)

      product.option_types << option_type unless product.option_types.include?(option_type)

      variant.option_values << option_value unless variant.option_values.include?(option_value)
    end

    def get_or_create_option_type(field)
      Spree::OptionType.where('name = :field or presentation = :field', field: field.to_s).first ||
        Spree::OptionType.create(name: field, presentation: field)
    end

    def get_or_create_option_value(option_type, value)
      option_type.option_values.where('name = :value or presentation = :value', value: value).first ||
        option_type.option_values.create(presentation: value, name: value)
    end

    def attach_image
      Spree::ProductImport.settings[:image_fields_variants].each do |field|
        find_and_attach_image_to(
          variant,
          product_information[field.to_sym],
          product_information[Spree::ProductImport.settings[:image_text_variants].to_sym]
        )
      end
    end

    def stock_items
      source_location = Spree::StockLocation.find_by(default: true)
      unless source_location
        logger.log('Seems that there are no SourceLocation set right?, so stock will not set.', :warn) if product_information[:stock] ||
                                                                                                          product_information[:backorderable]
        return
      end
      logger.log("SourceLocation: #{source_location.inspect}", :debug)

      stock_item = variant.stock_items.where(stock_location_id: source_location.id).first_or_initialize

      stock_item.send('backorderable=', product_information[:backorderable]) if product_information.key?(:backorderable) &&
                                                                                stock_item.respond_to?('backorderable=')

      stock_item.set_count_on_hand(product_information[:stock]) if product_information[:stock]
    end
  end
end
