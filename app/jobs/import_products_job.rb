class ImportProductsJob < ApplicationJob
  queue_as :default

  def perform(product_import)
    user = product_import.user
    begin
      product_import.import_data!(true)
      Spree::UserMailer.product_import_results(user).deliver_later
    rescue StandardError => exception
      Rails.logger.error("[ActiveJob] [ImportProductsJob] [#{job_id}] ID: #{product_import} #{exception}")
      product_import.error_message = exception.message
      product_import.failure
      Spree::UserMailer.product_import_results(user, "#{exception.message}  #{exception.backtrace.join('\n')}").deliver_later
    end
  end
end
