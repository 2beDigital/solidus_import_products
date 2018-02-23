module SolidusImportProducts
  class SaveProduct
    attr_accessor :product, :product_information, :logger

    include SolidusImportProducts::ImportHelper

    def self.call(options = {})
      new.call(options)
    end

    def call(args = { product: nil, product_information: nil })
      self.logger = SolidusImportProducts::Logger.instance
      self.product_information = args[:product_information]
      self.product = args[:product]

      logger.log("SAVE PRODUCT: #{product.inspect}", :debug)

      unless product.valid?
        msg = "A product could not be imported - here is the information we have:\n" +
            "#{product_information}, #{product.inspect} #{product.errors.full_messages.join(', ')}"
        logger.log(msg,:error)
        raise SolidusImportProducts::Exception::ProductError, msg
      end

      # TODO: this is for supporting translations.
      # if (product_information[:locale])
      #   add_translations(product, product_information)
      # end

      product.save

      #Associate our new product with any taxonomies that we need to worry about
      Spree::ProductImport.settings[:taxonomy_fields].each do |field|
        associate_product_with_taxon(product, field.to_s, product_information[field.to_sym], true)
      end

      #Finally, attach any images that have been specified
      Spree::ProductImport.settings[:image_fields_products].each do |field|
        find_and_attach_image_to(product, product_information[field.to_sym], product_information[Spree::ProductImport.settings[:image_text_products].to_sym])
      end

      if Spree::ProductImport.settings[:multi_domain_importing] && product.respond_to?(:stores)
        begin
          store = Store.find(
              :first,
              :conditions => ["id = ? OR code = ?",
                              product_information[ProductImport.settings[:store_field]],
                              product_information[ProductImport.settings[:store_field]]
              ]
          )

          product.stores << store
        rescue
          log("#{product.name} could not be associated with a store. Ensure that Spree's multi_domain extension is installed and that fields are mapped to the CSV correctly.")
        end
      end

      logger.log("#{product.name} successfully imported.\n")
      true
    end

    private

    # May be implemented via decorator if useful:
    #
    #    Spree::ProductImport.class_eval do
    #
    #      private
    #
    #      def after_product_built(product, product_information)
    #        super()
    #        # do something with the product
    #      end
    #    end
    def after_product_built(product, product_information)
      if (product_information[:locale])
        add_translations(product, product_information)
      end
    end

    # TODO: Translate slug
    def add_translations(product, product_information)
      localeProduct=product_information[:locale]
      if (localeProduct.nil?) then return end

      translations_names=product.translations.attribute_names
      #product_fields=product.attribute_names
      #Necesitamos "duplicar" el campo (de momento, slug) que nos sirve para detectar
      #si el producto existe. Por tanto, si estamos traduciendo este campo, lo tendremos
      #en dos columnas del csv. En una con el valor original, i en otra donde pondremos
      #la traducción.
      # if (product_information.include?(ProductImport.settings[:variant_comparator_field_i18n]) )
      #   translations_names.delete(ProductImport.settings[:variant_comparator_field].to_s)
      #   #translations_names << ProductImport.settings[:variant_comparator_field_i18n].to_s
      # end
      translation=product.translations.where(locale: localeProduct).first_or_initialize
      product_information.each do |key,value|
        if translations_names.include?(key.to_s)
          #Detectamos si el campo és el slug traducido, y en tal caso, lo añadimos
          #con el nombre "slug"
          #if (key.to_s==ProductImport.settings[:variant_comparator_field_i18n].to_s)
          #translation.send("#{ProductImport.settings[:variant_comparator_field].to_s}=", value)
          #product.attributes={ProductImport.settings[:variant_comparator_field].to_s => value, :locale => localeProduct}
          #else
          translation.send("#{key.to_s}=", value)
          #end
        end
      end
      translation.save
    end
  end
end
