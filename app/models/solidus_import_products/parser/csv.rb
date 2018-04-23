require 'csv'

module SolidusImportProducts
  module Parser
    class Csv < Base
      DEFAULT_CSV_ENCODING = 'utf-8'.freeze
      DEFAULT_CSV_SEPARATOR = ','.freeze

      attr_accessor :variant_option_fields, :mappings

      def initialize(data_file, options)
        self.data_file = data_file
        self.mappings = {}
        self.variant_option_fields = []
        encoding_csv = (options[:encoding_csv] if options) || DEFAULT_CSV_ENCODING
        separator_char = (options[:separator_char] if options) || DEFAULT_CSV_SEPARATOR
        csv_string = open(data_file, "r:#{encoding_csv}").read.encode('utf-8')
        self.rows = CSV.parse(csv_string, col_sep: separator_char)
        extract_column_mappings
      end

      # column_mappings
      # This method attempts to automatically map headings in the CSV files
      # with fields in the product and variant models.
      # Rows[0] is an array of headings for columns - SKU, Master Price, etc.)
      # @return a hash of symbol heading => column index pairs
      def column_mappings
        mappings
      end

      # variant_option_field?
      # Class method that check if a field is a variant option field
      # @return true or false
      def variant_option_field?(field)
        variant_option_fields.include?(field.to_s)
      end

      # data_rows
      # This method fetch the product rows.
      # @return a array of columns with product information
      def data_rows
        rows[1..-1]
      end

      # products_count
      # This method count the product rows.
      # @return a integer
      def products_count
        data_rows.count
      end

      protected

      def extract_column_mappings
        rows[0].each_with_index do |heading, index|
          break if heading.blank?
          field_name = heading.downcase.gsub(/\A\s*/, '').chomp.gsub(/\s/, '_')
          if field_name.include?('[opt]')
            field_name.gsub!('[opt]', '')
            variant_option_fields.push(field_name)
          end
          mappings[field_name.to_sym] = index
        end
      end
    end
  end
end
