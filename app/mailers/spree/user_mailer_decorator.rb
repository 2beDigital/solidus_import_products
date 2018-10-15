Spree::UserMailer.class_eval do

  def product_import_results(user, product_imports, error_message = nil)
    @user = user
    @error_message = error_message
    @product_imports = product_imports
    store = Spree::Store.default
    # attachments["import_products.log"] = File.read(Spree::ProductImport.settings[:log_to]) if @error_message.nil?
    result = error_message.nil? ? t('spree.emailer.import.result_success') : t('spree.emailer.import.result_error')
    mail(to: @user.email, from: from_address(store), subject: "#{t('spree.emailer.import.title')} #{result}")
  end

end
