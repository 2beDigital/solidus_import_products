module SolidusImportProducts
  class Engine < Rails::Engine
    engine_name 'import_products'

    config.autoload_paths += %W[#{config.root}/lib]

    def self.activate
      Dir.glob(File.join(File.dirname(__FILE__), '../app/**/*_decorator*.rb')) do |c|
        Rails.env.production? ? require(c) : load(c)
      end

      Dir.glob(File.join(File.dirname(__FILE__), '../../app/overrides/*.rb')) do |c|
        Rails.application.config.cache_classes ? require(c) : load(c)
      end

      Spree::UserMailer.send(:include, SolidusImportProducts::UserMailerExt)

      # TODO: replace the class_eval
      Spree::User.class_eval do
        has_many :product_imports, class_name: 'Spree::ProductImport', foreign_key: 'created_by'
      end
    end

    config.to_prepare &method(:activate).to_proc
  end
end
