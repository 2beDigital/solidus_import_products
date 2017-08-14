# This model is the master routine for uploading products
# Requires Paperclip and CSV to upload the CSV file and read it nicely.

# Original Author:: Josh McArthur
# License:: MIT
module Spree
  class ProductError < StandardError; end;
  class ImportError < StandardError; end;
  class SkuError < StandardError; end;

  class ProductImport < ActiveRecord::Base

    ENCODINGS= %w(UTF-8 iso-8859-1)

    has_attached_file :data_file, :path => "/product_data/data-files/:basename_:timestamp.:extension"
    validates_attachment_presence :data_file
    #Content type of csv vary in different browsers.
    validates_attachment :data_file, :presence => true, content_type: { content_type: ["text/csv", "text/plain", "text/comma-separated-values", "application/octet-stream", "application/vnd.ms-excel", "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"] }

    after_destroy :destroy_products

    serialize :product_ids, Array
    cattr_accessor :settings

    def products
      Product.where :id => product_ids
    end

    require 'csv'
    require 'pp'
    require 'open-uri'

    def destroy_products
      products.destroy_all
    end

    state_machine :initial => :created do

      event :start do
        transition :to => :started, :from => :created
      end
      event :complete do
        transition :to => :completed, :from => :started
      end
      event :failure do
        transition :to => :failed, :from => [:created, :started]
      end

      before_transition :to => [:failed] do |import|
        import.product_ids = []
        import.failed_at = Time.now
        import.completed_at = nil
      end

      before_transition :to => [:completed] do |import|
        import.failed_at = nil
        import.completed_at = Time.now
      end
    end
    #Return the number of rows in CSV.
    def productsCount
      rows = CSV.parse(open(self.data_file.url).read, :col_sep => separatorChar)
			#rows = CSV.parse(open(self.data_file.url).read, :col_sep => ",", :quote_char => "'")
      return rows.count
    end

    # def import
    #   rows = CSV.parse(open(self.data_file.url).read)
    #   delayed=rows.count>Spree::ProductImport.settings[:num_prods_for_delayed]
    #   if (delayed)
    #     ImportProductsJob.perform_later(self.id)
    #   else
    #     import_data!(Spree::ProductImport.settings[:transaction])
    #   end
    #   return delayed
    # end

    def state_datetime
      if failed?
        failed_at
      elsif completed?
        completed_at
      else
        updated_at
      end
    end

    def import_data!(_transaction=true)
      start
      if _transaction
        transaction do
          _import_data
        end
      else
        _import_data
      end
    end

    def _import_data
      begin
        log("import data start",:debug)
        @products_before_import = Spree::Product.with_translations().all
        @skus_of_products_before_import = @products_before_import.map(&:sku)
        csv_string=open(self.data_file.url,"r:#{encoding_csv}").read.encode('utf-8')
        rows = CSV.parse(csv_string, :col_sep => separatorChar)

        if ProductImport.settings[:first_row_is_headings]
          col = get_column_mappings(rows[0])
        else
          col = ProductImport.settings[:column_mappings]
        end

        rows[ProductImport.settings[:rows_to_skip]..-1].each do |row|
          product_information = {}

          #Automatically map 'mapped' fields to a collection of product information.
          #NOTE: This code will deal better with the auto-mapping function - i.e. if there
          #are named columns in the spreadsheet that correspond to product
          # and variant field names.

          col.each do |key, value|
            #Trim whitespace off the beginning and end of row fields
            row[value].try :strip!
            product_information[key] = row[value]
          end

          #Manually set available_on if it is not already set
          product_information[:available_on] = Date.today - 1.day if product_information[:available_on].nil?

          if (product_information[:shipping_category_id].nil?)
            sc = Spree::ShippingCategory.first
            product_information[:shipping_category_id] = sc.id unless sc.nil?
          end

          log("#{pp product_information}",:debug)

          variant_comparator_field = ProductImport.settings[:variant_comparator_field].try :to_sym
          variant_comparator_column = col[variant_comparator_field]

          if ProductImport.settings[:create_variants] and variant_comparator_column and
              #p = Product.with_translations().where(Product.table_name+'.'+variant_comparator_field.to_s => row[variant_comparator_column]).first #only(:product,:where)
              p = Product.with_translations().where(variant_comparator_field.to_s => row[variant_comparator_column]).first #only(:product,:where)
            # Product exists
            p.update_attribute(:deleted_at, nil) if p.deleted_at #Un-delete product if it is there
            p.variants.each { |variant| variant.update_attribute(:deleted_at, nil) }
            update_product(p,product_information)
          else
            #product doesn't exists
            if (@skus_of_products_before_import.include?(product_information[:sku]))
              log(msg="SKU #{product_information[:sku]} exists, but slug #{row[variant_comparator_column]} not exists!! ",:error)
              raise ProductError, msg
            end
            next unless create_product(product_information)
          end
        end

        #2BeDigital.We disable this option
        #if ProductImport.settings[:destroy_original_products]
        #@products_before_import.each { |p| p.destroy }
        #end
      end
      # Finished Importing!
      complete
      return [:notice, "Product data was successfully imported."]
    end

    private

    def create_product(params_hash)

      log("CREATE PRODUCT:"+params_hash.inspect)

      product = Product.new
      properties_hash = Hash.new

			#2BeDigital: Manually set retail_only if it is not already set
			params_hash[:retail_only] = 0 if params_hash[:retail_only].nil?
					
      # Array of special fields. Prevent adding them to properties.
      special_fields  = ProductImport.settings.values_at(
          :image_fields,
          :taxonomy_fields,
          :store_field,
          :variant_comparator_field
      ).flatten.map(&:to_s)

      params_hash.each do |field, value|
        if (field.to_s.eql?('price'))
          product.price=convertToPrice(value)
        elsif (product.respond_to?("#{field}="))
          product.send("#{field}=", value)
        elsif not special_fields.include?(field.to_s) and property = Property.where("lower(name) = ?", field).first
          properties_hash[property] = value
        end
      end

      save_product(product,params_hash,properties_hash,true)
    end

    def update_product(product,params_hash)

      log("UPATE PRODUCT:"+params_hash.inspect)
      properties_hash = Hash.new

			#2BeDigital: If exists retail_only key without value, we assign false, to avoid null values.
			if (params_hash.key?(:retail_only) and params_hash[:retail_only].nil?) 
				params_hash[:retail_only] = 0
			end
			
      # Array of special fields. Prevent adding them to properties.
      special_fields  = ProductImport.settings.values_at(
          :image_fields,
          :taxonomy_fields,
          :store_field,
          :variant_comparator_field
      ).flatten.map(&:to_s)

      # Here we only update product fields, because we update or create variant
      # after update the product.
      product_fields=product.attribute_names
      product_hash=Hash.new
      params_hash.each do |key,value|
        if product_fields.include?(key.to_s)
          product_hash[key]=value
        end
      end
      # We only assign fields of the products table.
      params_hash.each do |field, value|
        if (product_fields.include?(field.to_s))
          if (product.respond_to?("#{field}=") and params_hash[:locale].nil?)
            product.send("#{field}=", value)
          end
        elsif not special_fields.include?(field.to_s) and property = Property.where("lower(name) = ?", field).first
          properties_hash[property] = value
        end
      end

      save_product(product,params_hash,properties_hash,false)
    end

    def save_product(product,params_hash,properties_hash,create)
      log("SAVE PRODUCT:"+product.inspect)

      #We can't continue without a valid product here
      unless product.valid?
        log(msg = "A product could not be imported - here is the information we have:\n" +
            "#{pp params_hash}, #{product.inspect} #{product.errors.full_messages.join(', ')}",:error)
        raise ProductError, msg
      end

      log("Save product:"+product.name)

      after_product_built(product, params_hash)


      #Save the object before creating asssociated objects
      product.save and product_ids << product.id
      log("Saved object before creating associated objects for: #{product.name}")

      #In creates, slug is assigned automatically, and is not assigned to the csv value.
      #So we have to do this assginment manually.
      if (product.slug!=params_hash[:slug])
        product.slug=params_hash[:slug]
        product.save
      end


      variant=create_variant_for(product, :with => params_hash)

      #Associate properties with product
      properties_hash.each do |property, value|
        product_property = Spree::ProductProperty.where(:product_id => product.id, :property_id => property.id).first_or_initialize
        product_property.value = value
        product_property.save!
      end

      #Associate our new product with any taxonomies that we need to worry about
      ProductImport.settings[:taxonomy_fields].each do |field|
        associate_product_with_taxon(product, field.to_s, params_hash[field.to_sym],create)
      end

      #Finally, attach any images that have been specified
      ProductImport.settings[:image_fields_products].each do |field|
        find_and_attach_image_to(product, params_hash[field.to_sym], params_hash[ProductImport.settings[:image_text_products].to_sym])
      end

      if ProductImport.settings[:multi_domain_importing] && product.respond_to?(:stores)
        begin
          store = Store.find(
              :first,
              :conditions => ["id = ? OR code = ?",
                              params_hash[ProductImport.settings[:store_field]],
                              params_hash[ProductImport.settings[:store_field]]
              ]
          )

          product.stores << store
        rescue
          log("#{product.name} could not be associated with a store. Ensure that Spree's multi_domain extension is installed and that fields are mapped to the CSV correctly.")
        end
      end

      log("#{product.name} successfully imported.\n")
      return true
    end

    # create_variant_for
    # This method assumes that some form of checking has already been done to
    # make sure that we do actually want to create a variant.
    # It performs a similar task to a product, but it also must pick up on
    # size/color options
    def create_variant_for(product, options = {:with => {}})
      return if options[:with].nil?

      # Just update variant if exists
      variant = Variant.find_by_sku(options[:with][:sku])
      raise SkuError, "SKU #{variant.sku} should belongs to #{product.inspect} but was #{variant.product.inspect}" if variant && variant.product != product
      if !variant
        variant = product.variants.new
        variant.id = options[:with][:id]
      else
        options[:with].delete(:id)
      end

      field = ProductImport.settings[:variant_comparator_field]
      log("VARIANT:: #{variant.inspect}  /// #{options.inspect } /// #{options[:with][field]} /// #{field}",:debug)

      options[:with].each do |field, value|
        if (field.to_s.eql?('price'))
          variant.price=convertToPrice(value)
        else
          variant.send("#{field}=", value) if variant.respond_to?("#{field}=")
        end
        #We only apply OptionTypes if value is not null.
        if (value && !(field.to_s =~ /^(sku|slug|name|description|price|on_hand|taxonomies|image_product|alt_product|available_on|shipping_category_id).*$/))
          applicable_option_type = OptionType.where(name: field.to_s).or(OptionType.where(presentation: field.to_s)).first
          if applicable_option_type.is_a?(OptionType)
            product.option_types << applicable_option_type unless product.option_types.include?(applicable_option_type)
            opt_value = applicable_option_type.option_values.where(presentation: value).or(applicable_option_type.option_values.where(name:value)).first
            opt_value = applicable_option_type.option_values.create(:presentation => value, :name => value) unless opt_value
            variant.option_values << opt_value unless variant.option_values.include?(opt_value)
          end
        end
      end

      log("VARIANT PRICE #{variant.inspect} /// #{variant.price}",:debug)

      if variant.valid?
        variant.save
        #Finally, attach any images that have been specified
        ProductImport.settings[:image_fields_variants].each do |field|
          find_and_attach_image_to(variant, options[:with][field.to_sym], options[:with][ProductImport.settings[:image_text_variants].to_sym])
        end

        #Log a success message
        log("Variant of SKU #{variant.sku} successfully imported.\n")
      else
        log("A variant could not be imported - here is the information we have:\n" +
                "#{pp options[:with]}, #{variant.errors.full_messages.join(', ')}")
        return false
      end

      #Stock item
      source_location = Spree::StockLocation.find_by(default: true)
      log("SourceLocation: #{source_location.inspect}",:debug)
      if source_location
        stock_item = variant.stock_items.where(stock_location_id: source_location.id).first_or_initialize
        log("StockItem: #{stock_item.inspect}",:debug)
        log("OnHand: #{options[:with][:on_hand]}",:debug)
        #We only update the stock if stock is not blank.
				if (options[:with][:backorderable])
				  if stock_item.respond_to?("backorderable=")
						stock_item.send("backorderable=", options[:with][:backorderable])
					end
        end
        if (options[:with][:on_hand])
          stock_item.set_count_on_hand(options[:with][:on_hand])
        end
      end

      variant
    end

    # get_column_mappings
    # This method attempts to automatically map headings in the CSV files
    # with fields in the product and variant models.
    # If the headings of columns are going to be called something other than this,
    # or if the files will not have headings, then the manual initializer
    # mapping of columns must be used.
    # Row is an array of headings for columns - SKU, Master Price, etc.)
    # @return a hash of symbol heading => column index pairs
    def get_column_mappings(row)
      mappings = {}
      row.each_with_index do |heading, index|
        # Stop collecting headings, if heading is empty
        if not heading.blank?
          mappings[heading.downcase.gsub(/\A\s*/, '').chomp.gsub(/\s/, '_').to_sym] = index
        else
          break
        end
      end
      mappings
    end


    ### MISC HELPERS ####

    # Log a message to a file - logs in standard Rails format to logfile set up in the import_products initializer
    # and console.
    # Message is string, severity symbol - either :info, :warn or :error

    def log(message, severity = :info)
      @rake_log ||= ActiveSupport::Logger.new(ProductImport.settings[:log_to])
      message = "[#{Time.now.to_s(:db)}] [#{severity.to_s.capitalize}] #{message}\n"
      @rake_log.send severity, message
      puts message
    end


    ### IMAGE HELPERS ###

    # find_and_attach_image_to
    # This method attaches images to products. The images may come
    # from a local source (i.e. on disk), or they may be online (HTTP/HTTPS).
    def find_and_attach_image_to(product_or_variant, filename,alt_text)
      return if filename.blank?

      #The image can be fetched from an HTTP or local source - either method returns a Tempfile
      file = filename =~ /\Ahttp[s]*:\/\// ? fetch_remote_image(filename) : fetch_local_image(filename)

      #An image has an attachment (the image file) and some object which 'views' it
      product_image = Spree::Image.new({:attachment => file,
                                        :viewable_id => product_or_variant.id,
                                        :viewable_type => "Spree::Variant",
                                        :alt => alt_text,
                                        :position => product_or_variant.images.length
                                       })

      log("#{product_image.viewable_id} : #{product_image.viewable_type} : #{product_image.position}",:debug)

      product_or_variant.images << product_image if product_image.save
    end

    # This method is used when we have a set location on disk for
    # images, and the file is accessible to the script.
    # It is basically just a wrapper around basic File IO methods.
    def fetch_local_image(filename)
      filename = ProductImport.settings[:product_image_path] + filename
      unless File.exists?(filename) && File.readable?(filename)
        log("Image #{filename} was not found on the server, so this image was not imported.", :warn)
        return nil
      else
        return File.open(filename, 'rb')
      end
    end


    #This method can be used when the filename matches the format of a URL.
    # It uses open-uri to fetch the file, returning a Tempfile object if it
    # is successful.
    # If it fails, it in the first instance logs the HTTP error (404, 500 etc)
    # If it fails altogether, it logs it and exits the method.
    def fetch_remote_image(filename)
      begin
        io = open(URI.parse(filename))
        def io.original_filename; base_uri.path.split('/').last; end
        return io
      rescue OpenURI::HTTPError => error
        log("Image #{filename} retrival returned #{error.message}, so this image was not imported")
      rescue => error
        log("Image #{filename} could not be downloaded, so was not imported. #{error.message}")
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

      #Using find_or_create_by_name is more elegant, but our magical params code automatically downcases
      # the taxonomy name, so unless we are using MySQL, this isn't going to work.
      # taxonomy_name = taxonomy
      # taxonomy = Taxonomy.find(:first, :conditions => ["lower(name) = ?", taxonomy])
      # taxonomy = Taxonomy.create(:name => taxonomy_name.capitalize) if taxonomy.nil? && ProductImport.settings[:create_missing_taxonomies]

      taxon_hierarchy.split(/\s*\|\s*/).each do |hierarchy|
        hierarchy = hierarchy.split(/\s*>\s*/)
        taxonomy = Spree::Taxonomy.with_translations.where("lower(spree_taxonomy_translations.name) = ?", hierarchy.first.downcase).first
        taxonomy = Taxonomy.create(:name => hierarchy.first.capitalize) if taxonomy.nil? && ProductImport.settings[:create_missing_taxonomies]
        last_taxon = taxonomy.root

        hierarchy.shift
        hierarchy.each do |taxon|
          #last_taxon = last_taxon.children.find_or_create_by_name_and_taxonomy_id(taxon, taxonomy.id)
          last_taxon = last_taxon.children.find_or_create_by(name: taxon, taxonomy_id: taxonomy.id)
        end

        #Spree only needs to know the most detailed taxonomy item
        product.taxons << last_taxon unless product.taxons.include?(last_taxon)
      end
      if (putInTop and defined?(SpreeSortProductsTaxbundleon))
        if(SpreeSortProductsTaxon::Config.activated)
          product.put_in_taxons_top(product.taxons)
        end
      end
    end
    ### END TAXON HELPERS ###

    # May be implemented via decorator if useful:
    #
    #    Spree::ProductImport.class_eval do
    #
    #      private
    #
    #      def after_product_built(product, params_hash)
    #        super()
    #        # do something with the product
    #      end
    #    end
    def after_product_built(product, params_hash)
      if (params_hash[:locale])
        add_translations(product, params_hash)
      end
    end

    # TODO: Translate slug
    def add_translations(product, params_hash)
      localeProduct=params_hash[:locale]
      if (localeProduct.nil?) then return end

      translations_names=product.translations.attribute_names
      #product_fields=product.attribute_names
      #Necesitamos "duplicar" el campo (de momento, slug) que nos sirve para detectar
      #si el producto existe. Por tanto, si estamos traduciendo este campo, lo tendremos
      #en dos columnas del csv. En una con el valor original, i en otra donde pondremos
      #la traducción.
      # if (params_hash.include?(ProductImport.settings[:variant_comparator_field_i18n]) )
      #   translations_names.delete(ProductImport.settings[:variant_comparator_field].to_s)
      #   #translations_names << ProductImport.settings[:variant_comparator_field_i18n].to_s
      # end
      translation=product.translations.where(locale: localeProduct).first_or_initialize
      params_hash.each do |key,value|
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
    #Special process of prices because of locales and different decimal separator characters.
    #We want to get a format with dot as decimal separator and without thousand separator
    def convertToPrice(priceStr)
      punt=priceStr.index('.')
      coma=priceStr.index(',')
      #If the string contains dot and commas, we process it. If not, we replace comma by dot.
      if (coma!=nil && punt!=nil)
        #If dot is before comma, the format is x.xxx,xx so we delete the dot.
        #If not, the format is x,xxx.xx so we delete the comma.
        if (punt<coma)
          priceStr=priceStr.gsub('.', '')
        else
          priceStr=priceStr.gsub(',', '')
        end
      end
      #We replace comma by dot.
      return priceStr.gsub(',', '.').to_f
    end
  end
end
