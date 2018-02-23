require 'active_support/concern'

module SolidusImportProducts
  module ImportHelper
    extend ActiveSupport::Concern

    require 'open-uri'

    included do
      # Special process of prices because of locales and different decimal separator characters.
      # We want to get a format with dot as decimal separator and without thousand separator
      def convert_to_price(price_str)
        raise SolidusImportProducts::Exception::InvalidPrice unless price_str
        punt = price_str.index('.')
        coma = price_str.index(',')
        if !coma.nil? && !punt.nil?
          price_str.gsub!(punt < coma ? '.' : ',', '')
        end
        price_str.tr(',', '.').to_f
      end

      ### IMAGE HELPERS ###
      # find_and_attach_image_to
      # This method attaches images to products. The images may come
      # from a local source (i.e. on disk), or they may be online (HTTP/HTTPS).
      def find_and_attach_image_to(product_or_variant, filename,alt_text)
        return if filename.blank?

        # The image can be fetched from an HTTP or local source - either method returns a Tempfile
        file = filename =~ /\Ahttp[s]*:\/\// ? fetch_remote_image(filename) : fetch_local_image(filename)

        #An image has an attachment (the image file) and some object which 'views' it
        product_image = Spree::Image.new({:attachment => file,
          :viewable_id => product_or_variant.id,
          :viewable_type => "Spree::Variant",
          :alt => alt_text,
          :position => product_or_variant.images.length
          })

        logger.log("#{product_image.viewable_id} : #{product_image.viewable_type} : #{product_image.position}",:debug)

        product_or_variant.images << product_image if product_image.save
      end

      # This method is used when we have a set location on disk for
      # images, and the file is accessible to the script.
      # It is basically just a wrapper around basic File IO methods.
      def fetch_local_image(filename)
        filename = ProductImport.settings[:product_image_path] + filename
        unless File.exists?(filename) && File.readable?(filename)
          logger.log("Image #{filename} was not found on the server, so this image was not imported.", :warn)
          return nil
        else
          return File.open(filename, 'rb')
        end
      end

      # This method can be used when the filename matches the format of a URL.
      # It uses open-uri to fetch the file, returning a Tempfile object if it
      # is successful.
      # If it fails, it in the first instance logger.logs the HTTP error (404, 500 etc)
      # If it fails altogether, it logger.logs it and exits the method.
      def fetch_remote_image(filename)
        begin
          io = open(URI.parse(filename))
          def io.original_filename; base_uri.path.split('/').last; end
          return io
        rescue OpenURI::HTTPError => error
          logger.log("Image #{filename} retrival returned #{error.message}, so this image was not imported")
        rescue => error
          logger.log("Image #{filename} could not be downloaded, so was not imported. #{error.message}")
        end
      end

      ### TAXON HELPERS ###

      # associate_product_with_taxon
      # This method accepts three formats of taxon hierarchy strings which will
      # associate the given products with taxons:
      # 1. A string on it's own will will just find or create the taxon and
      # add the product to it. e.g. taxonomy = "Category", taxon_hierarchy = "Tools" will
      # add the product to the 'Tools' category.
      # 2. A item > item > item structured string will read this like a tree - allowing
      # a particular taxon to be picked out
      # 3. An item > item & item > item will work as above, but will associate multiple
      # taxons with that product. This form should also work with format 1.
      def associate_product_with_taxon(product, taxonomy, taxon_hierarchy,putInTop)
        return if product.nil? || taxonomy.nil? || taxon_hierarchy.nil?

        # Using find_or_create_by_name is more elegant, but our magical params code automatically downcases
        # the taxonomy name, so unless we are using MySQL, this isn't going to work.
        # taxonomy_name = taxonomy
        # taxonomy = Taxonomy.find(:first, :conditions => ["lower(name) = ?", taxonomy])
        # taxonomy = Taxonomy.create(:name => taxonomy_name.capitalize) if taxonomy.nil? && ProductImport.settings[:create_missing_taxonomies]

        taxon_hierarchy.split(/\s*\|\s*/).each do |hierarchy|
          hierarchy = hierarchy.split(/\s*>\s*/)
          taxonomy = Spree::Taxonomy.with_translations.where("lower(spree_taxonomy_translations.name) = ?", hierarchy.first.downcase).first
          taxonomy = Taxonomy.create(:name => hierarchy.first.capitalize) if taxonomy.nil? && ProductImport.settings[:create_missing_taxonomies]
          # Check if the Taxonomy is valid
          unless taxonomy.valid?
            logger.log(msg = "A product could not be imported - here is the information we have:\n" +
              "Product: #{product.inspect}, Taxonomy: #{taxon_hierarchy}, Errors: #{taxonomy.errors.full_messages.join(', ')} \n",:error)
            raise ProductError, msg
          end

          last_taxon = taxonomy.root

          hierarchy.shift
          hierarchy.each do |taxon|
            #last_taxon = last_taxon.children.find_or_create_by_name_and_taxonomy_id(taxon, taxonomy.id)
            last_taxon = last_taxon.children.find_or_create_by(name: taxon, taxonomy_id: taxonomy.id)
            #Check if the Taxonomy is valid
            unless last_taxon.valid?
              logger.log(msg = "A product could not be imported - here is the information we have:\n" +
                "Product: #{product.inspect}, Taxonomy: #{taxonomy.inspect}, Taxon: #{last_taxon.inspect}, #{last_taxon.errors.full_messages.join(', ')}",:error)
              raise ProductError, msg
            end
          end
          #Spree only needs to know the most detailed taxonomy item
          product.taxons << last_taxon unless product.taxons.include?(last_taxon)
        end

        if (putInTop and defined?(SolidusSortProductsTaxon))
          if(SolidusSortProductsTaxon::Config.activated)
            unless product.put_in_taxons_top(product.taxons)
              logger.log(msg = "A product could not be imported - here is the information we have:\n" +
                "Product: #{product.inspect}, Taxons: #{product.taxons}, #{product.errors.full_messages.join(', ')}",:error)
              raise SolidusImportProducts::Exception::ProductError, msg
            end
          end
        end
      end
      ### END TAXON HELPERS ###
    end
  end
end
