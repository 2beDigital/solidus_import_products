require 'csv'

module SolidusImportProducts
  class Parser
    attr_accessor :rows, :data_file

    def initialize(data_file, encoding_csv, separator_char)
      self.data_file = data_file
      csv_string = open(data_file, "r:#{encoding_csv}").read.encode('utf-8')
      self.rows = CSV.parse(csv_string, col_sep: separator_char)
    end

    def column_mappings
      if Spree::ProductImport.settings[:first_row_is_headings]
        get_column_mappings(rows[0])
      else
        Spree::ProductImport.settings[:column_mappings]
      end
    end

    def data_rows
      rows[Spree::ProductImport.settings[:rows_to_skip]..-1]
    end

    def products_count
      data_rows.count
    end

    private

    # get_column_mappings
    # This method attempts to automatically map headings in the CSV files
    # with fields in the product and variant models.
    # If the headings of columns are going to be called something other than this,
    # or if the files will not have headings, then the manual initializer
    # mapping of columns must be used.
    # Row is an array of headings for columns - SKU, Master Price, etc.)
    # @return a hash of symbol heading => column index pairs
    def get_column_mappings(row)
      mappings = {}
      row.each_with_index do |heading, index|
        # Stop collecting headings, if heading is empty
        if not heading.blank?
          mappings[heading.downcase.gsub(/\A\s*/, '').chomp.gsub(/\s/, '_').to_sym] = index
        else
          break
        end
      end
      mappings
    end
  end
end
