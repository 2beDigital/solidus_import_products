class ImportProductsJob < ApplicationJob
  queue_as :default

  def perform(product_imports)
    user = product_imports.user
    begin
      SolidusImportProducts::Import.call(product_imports: product_imports)
      Spree::UserMailer.product_import_results(user, product_imports).deliver_later
    rescue StandardError => exception
      Rails.logger.error("[ActiveJob] [ImportProductsJob] [#{job_id}] ID: #{product_imports} #{exception}")
      Spree::UserMailer.product_import_results(user, product_imports, "#{exception.message}  #{exception.backtrace.join('\n')}").deliver_later
    end
  end
end
