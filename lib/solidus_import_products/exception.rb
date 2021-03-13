# frozen_string_literal: true

module SolidusImportProducts
  module Exception
    class Base < StandardError; end

    class ProductError < Base; end
    class VariantError < Base; end
    class ImportError < Base; end
    class SkuError < Base; end
    class InvalidPrice < Base; end

    class AbstractMthodCall < Base
      def initialize(msg = 'This methid should be implemented in the subclass')
        super
      end
    end

    class InvalidParseStrategy < Base; end
  end
end
