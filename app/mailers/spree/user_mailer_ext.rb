module ImportProducts
  module UserMailerExt
    def self.included(base)
      base.class_eval do
        def product_import_results(user, error_message = nil)
          @user = user
          @error_message = error_message
          from=Spree::Config.mails_from
          #attachments["import_products.log"] = File.read(Spree::ProductImport.settings[:log_to]) if @error_message.nil?
          mail(:to => @user.email, :from => from, :subject => "Spree: Import Products #{error_message.nil? ? "Success" : "Failure"}")
        end
      end
    end
  end
end
