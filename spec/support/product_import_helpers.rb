module ProductImportHelpers
  def create_import(filename)
    Spree::ProductImport.create(
      data_file: File.new(File.join(File.dirname(__FILE__), '..', 'fixtures', filename)),
      separatorChar: ','
    )
  end
end
