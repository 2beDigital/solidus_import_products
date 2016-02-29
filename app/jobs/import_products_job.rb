class ImportProductsJob < ActiveJob::Base
  queue_as :default

  after_perform :notify_admin

  rescue_from(StandardError) do |exception|
    Spree::UserMailer.product_import_results(Spree::User.admin.first, exception.message+" "+exception.backtrace.join("\n")).deliver
  end

  def perform(product_id)
    log("perform")
    log ("productimportid: #{product_id}")
    products=Spree::ProductImport.find(product_id)
    log ("productimport found!")
    products.import_data!(Spree::ProductImport.settings[:transaction])
  end

  def notify_admin
    # Spree::UserMailer.product_import_results(Spree::User.admin.first).deliver_later
    puts "*********************************************************"
    puts "*********************************************************"
    puts "==================== Import Complete ===================="
    puts "*********************************************************"
    puts "*********************************************************"
  end
  private
  def log(message, severity = :info)
    @rake_log ||= ActiveSupport::Logger.new(Spree::ProductImport.settings[:log_to])
    message = "[#{Time.now.to_s(:db)}] [#{severity.to_s.capitalize}] #{message}\n"
    @rake_log.send severity, message
    puts message
  end
end
