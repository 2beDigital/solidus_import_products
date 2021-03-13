# frozen_string_literal: true

module SolidusImportProducts
  module Parser
    def parse(strategy, data_file, options)
      raise SolidusImportProducts::Exception::InvalidParseStrategy unless strategy == :csv

      Parser::Csv.new(data_file, options)
    end

    module_function :parse
  end
end
