module SolidusImportProducts
  # CreateVariant
  # This method assumes that some form of checking has already been done to
  # make sure that we do actually want to create a variant.
  # It performs a similar task to a product, but it also must pick up on
  # size/color options
  class CreateVariant
    attr_accessor :product, :product_information, :logger

    include SolidusImportProducts::ImportHelper

    def self.call(options = {})
      new.call(options)
    end

    def call(args = { product: nil, product_information: nil })
      self.logger = SolidusImportProducts::Logger.instance
      self.product_information = args[:product_information]
      self.product = args[:product]
      return if product_information.nil?

      # Just update variant if exists
      variant = Spree::Variant.find_by_sku(product_information[:sku])
      raise SolidusImportProducts::Exception::SkuError, "SKU #{variant.sku} should belongs to #{product.inspect} but was #{variant.product.inspect}" if variant && variant.product != product

      if variant
        product_information.delete(:id)
      else
        variant = product.variants.new
        variant.id = product_information[:id]
      end

      variant_comparator_field = Spree::ProductImport.settings[:variant_comparator_field]
      logger.log("VARIANT:: #{variant.inspect} /// #{product_information[variant_comparator_field]} /// #{variant_comparator_field}",:debug)

      product_information.each do |field, value|
        if (field.to_s.eql?('price'))
          variant.price = convert_to_price(value)
        else
          variant.send("#{field}=", value) if variant.respond_to?("#{field}=")
        end
        #We only apply OptionTypes if value is not null.
        if (value && !(field.to_s =~ /^(sku|slug|name|description|price|on_hand|taxonomies|image_product|alt_product|available_on|shipping_category_id).*$/))
          applicable_option_type = Spree::OptionType.where(name: field.to_s).or(Spree::OptionType.where(presentation: field.to_s)).first
          if applicable_option_type.is_a?(Spree::OptionType)
            product.option_types << applicable_option_type unless product.option_types.include?(applicable_option_type)
            opt_value = applicable_option_type.option_values.where(presentation: value).or(applicable_option_type.option_values.where(name:value)).first
            opt_value = applicable_option_type.option_values.create(:presentation => value, :name => value) unless opt_value
            variant.option_values << opt_value unless variant.option_values.include?(opt_value)
          end
        end
      end

      logger.log("VARIANT PRICE #{variant.inspect} /// #{variant.price}",:debug)

      if variant.valid?
        variant.save
        #Finally, attach any images that have been specified
        Spree::ProductImport.settings[:image_fields_variants].each do |field|
          find_and_attach_image_to(variant, product_information[field.to_sym], product_information[Spree::ProductImport.settings[:image_text_variants].to_sym])
        end

        #Log a success message
        logger.log("Variant of SKU #{variant.sku} successfully imported.\n")
      else
        message = "A variant could not be imported - here is the information we have:\n" +
                "#{product_information}, #{variant.errors.full_messages.join(', ')}"
        logger.log(message, :error)
        raise SolidusImportProducts::Exception::VariantError, msg
      end

      #Stock item
      source_location = Spree::StockLocation.find_by(default: true)
      logger.log("SourceLocation: #{source_location.inspect}",:debug)
      if source_location
        stock_item = variant.stock_items.where(stock_location_id: source_location.id).first_or_initialize
        logger.log("StockItem: #{stock_item.inspect}",:debug)
        logger.log("OnHand: #{product_information[:on_hand]}",:debug)
        #We only update the stock if stock is not blank.
				if (product_information[:backorderable])
				  if stock_item.respond_to?("backorderable=")
						stock_item.send("backorderable=", product_information[:backorderable])
					end
        end
        if (product_information[:on_hand])
          stock_item.set_count_on_hand(product_information[:on_hand])
        end
      end

      variant
    end
  end
end
