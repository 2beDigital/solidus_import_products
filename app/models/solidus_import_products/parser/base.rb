# frozen_string_literal: true

module SolidusImportProducts
  module Parser
    class Base
      attr_accessor :rows, :data_file, :image_fields, :variant_image_fields, :property_fields

      # column_mappings
      # This method attempts to automatically map headings in the CSV files
      # with fields in the product and variant models.
      # Rows[0] is an array of headings for columns - SKU, Master Price, etc.)
      # @return a hash of symbol heading => column index pairs
      def column_mappings
        raise SolidusImportProducts::AbstractMthodCall
      end

      def data_rows
        raise SolidusImportProducts::AbstractMthodCall
      end

      def products_count
        raise SolidusImportProducts::AbstractMthodCall
      end
    end
  end
end
