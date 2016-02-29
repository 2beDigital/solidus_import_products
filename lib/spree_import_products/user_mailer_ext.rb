module SpreeImportProducts
  module UserMailerExt
    def self.included(base)
      base.class_eval do
        def product_import_results(user, error_message = nil)
          @user = user
          @error_message = error_message
          attachments["spree_import_products.log"] = File.read(Spree::ProductImport.settings[:log_to]) if @error_message.nil?
          mail(:to => @user.email, :from => 'sergi.carrasco@gmail.com', :subject => "Spree: Import Products #{error_message.nil? ? "Success" : "Failure"}")
        end
      end
    end
  end
end
