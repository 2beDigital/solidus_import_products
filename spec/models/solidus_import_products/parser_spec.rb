# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SolidusImportProducts::Parser do
  describe '#parse' do
    describe '#csv' do
      subject(:parse) { described_class.parse(:csv, csv_file, nil) }

      let(:csv_file) { File.new(File.join(File.dirname(__FILE__), '..', '..', 'fixtures', 'valid.csv')) }

      it { expect(parse).to be_a SolidusImportProducts::Parser::Csv }
    end
    describe 'invalid strategy' do
      subject(:parse) { described_class.parse(:invalid_factory, 'foo', nil) }

      it { expect { parse }.to raise_error SolidusImportProducts::Exception::InvalidParseStrategy }
    end
  end
end
