# frozen_string_literal: true

module Spree
  module UserMailerDecorator
    def product_import_results(user, product_imports, error_message = nil)
      @user = user
      @error_message = error_message
      @product_imports = product_imports
      store = Spree::Store.default
      # attachments["import_products.log"] =
      # File.read(Spree::ProductImport.settings[:log_to]) if @error_message.nil?
      result = t('spree.emailer.import.result_success')
      result = t('spree.emailer.import.result_error') unless error_message.nil?
      subject = "#{t('spree.emailer.import.title')} #{result}"
      mail(to: @user.email, from: from_address(store), subject: subject)
    end

    ::Spree::UserMailer.prepend self
  end
end
