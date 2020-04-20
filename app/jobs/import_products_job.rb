# frozen_string_literal: true

class ImportProductsJob < ApplicationJob
  queue_as :default

  def perform(product_imports)
    user = product_imports.user
    begin
      SolidusImportProducts::Import.call(product_imports: product_imports)
      Spree::UserMailer.product_import_results(user, product_imports).deliver_later
    rescue StandardError => e
      Rails.logger.error("[ActiveJob] [ImportProductsJob] [#{job_id}] ID: #{product_imports} #{e}")
      error_message = "#{e.message} #{e.backtrace.join('\n')}"
      Spree::UserMailer.product_import_results(user, product_imports, error_message).deliver_later
    end
  end
end
