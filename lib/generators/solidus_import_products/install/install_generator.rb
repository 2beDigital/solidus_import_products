module SolidusImportProducts
  module Generators
    class InstallGenerator < Rails::Generators::Base
      def self.source_paths
        paths = superclass.source_paths
        paths << File.expand_path('../templates', "../../#{__FILE__}")
        paths << File.expand_path('../templates', "../#{__FILE__}")
        paths << File.expand_path('../templates', __FILE__)
        paths.flatten
      end

      def add_migrations
        run 'bundle exec rake railties:install:migrations FROM=import_products'
      end

      def add_files
        template 'config/initializers/solidus_import_product_settings.rb', 'config/initializers/solidus_import_product_settings.rb'
      end

      def run_migrations
        res = ask 'Would you like to run the migrations now? [Y/n]'
        if res == '' || res.casecmp('y').zero?
          run 'bundle exec rake db:migrate'
        else
          puts "Skiping rake db:migrate, don't forget to run it!"
        end
      end
    end
  end
end
