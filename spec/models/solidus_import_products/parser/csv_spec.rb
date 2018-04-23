require 'spec_helper'

RSpec.describe SolidusImportProducts::Parser::Csv do
  let(:csv_file) { File.new(File.join(File.dirname(__FILE__), '..', '..', '..', 'fixtures', 'products_with_properties.csv')) }

  describe 'basic' do
    subject(:csv_parsed) { described_class.new(csv_file, options) }

    let(:options) {}

    it { expect(csv_parsed).to be_a described_class }
    # TODO, better test for this.
    it { expect(csv_parsed.column_mappings.size).to eq 17 }
    it { expect(csv_parsed.products_count).to eq 3 }
    it { expect(csv_parsed.variant_option_fields).to eq ['tshirt-color', 'tshirt-size'] }
  end
end
