# frozen_string_literal: true

module SolidusImportProducts
  class Logger
    include Singleton

    attr_accessor :logger

    def initialize
      self.logger = ActiveSupport::Logger.new(Spree::ProductImport.settings[:log_to])
    end

    def log(message, severity = :info)
      logger.send severity, "[#{Time.now.to_s(:db)}] [#{severity.to_s.capitalize}] #{message}\n"
    end
  end
end
