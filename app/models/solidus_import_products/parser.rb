require 'csv'

module SolidusImportProducts
  class Parser
    attr_accessor :rows, :data_file

    def initialize(data_file, encoding_csv, separator_char)
      self.data_file = data_file
      csv_string = open(data_file, "r:#{encoding_csv}").read.encode('utf-8')
      self.rows = CSV.parse(csv_string, col_sep: separator_char)
    end

    # column_mappings
    # This method attempts to automatically map headings in the CSV files
    # with fields in the product and variant models.
    # Rows[0] is an array of headings for columns - SKU, Master Price, etc.)
    # @return a hash of symbol heading => column index pairs
    def column_mappings
      mappings = {}
      rows[0].each_with_index do |heading, index|
        break if heading.blank?
        mappings[heading.downcase.gsub(/\A\s*/, '').chomp.gsub(/\s/, '_').to_sym] = index
      end
      mappings
    end

    def data_rows
      rows[Spree::ProductImport.settings[:rows_to_skip]..-1]
    end

    def products_count
      data_rows.count
    end
  end
end
