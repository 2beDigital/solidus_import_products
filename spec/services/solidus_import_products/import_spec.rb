# frozen_string_literal: true
# rubocop:disable Lint/HandleExceptions

require 'spec_helper'

module SolidusImportProducts
  describe Import do
    let(:valid_import) { create(:product_import) }
    let(:full_valid_import) { create(:full_product_import) }
    let(:invalid_import) { create(:invalid_product_import) }

    describe 'Basic functionality' do
      describe 'success' do
        subject(:valid) { SolidusImportProducts::Import.call(product_imports: valid_import) }

        before { valid_import }

        it 'call row service 3 times' do
          expect(SolidusImportProducts::ProcessRow).to receive(:call)
            .with(
              parser: kind_of(SolidusImportProducts::Parser::Base),
              product_imports: valid_import,
              row: duck_type(:each),
              col: kind_of(Hash),
              skus_of_products_before_import: kind_of(Array),
              image_path: kind_of(String)
            ).exactly(3).times
          valid
        end

        it 'change state to completed' do
          allow(SolidusImportProducts::ProcessRow).to receive(:call)
            .with(
              parser: kind_of(SolidusImportProducts::Parser::Base),
              product_imports: valid_import,
              row: duck_type(:each),
              col: kind_of(Hash),
              skus_of_products_before_import: kind_of(Array),
              image_path: kind_of(String)
            ).and_return true
          expect { valid }.to change { valid_import.reload.state }.to 'completed'
        end
      end

      describe 'error' do
        subject(:invalid) { SolidusImportProducts::Import.call(product_imports: invalid_import) }

        before do
          invalid_import
          allow(SolidusImportProducts::ProcessRow).to receive(:call)
            .with(
              parser: kind_of(SolidusImportProducts::Parser::Base),
              product_imports: invalid_import,
              row: duck_type(:each),
              col: kind_of(Hash),
              skus_of_products_before_import: kind_of(Array),
              image_path: kind_of(String)
            ).and_raise SolidusImportProducts::Exception::Base
        end

        it { expect { invalid }.to raise_error SolidusImportProducts::Exception::Base }

        it 'change state to failure' do
          expect do
            begin
              invalid
            rescue SolidusImportProducts::Exception::Base
            end
          end.to change { invalid_import.reload.state }.to 'failed'
        end
      end
    end

    describe 'Functional test' do
      describe 'on valid csv', vcr: { cassette_name: 'images/success_remote' } do
        subject(:valid) { SolidusImportProducts::Import.call(product_imports: full_valid_import) }

        let(:product) { Spree::Product.last(2).first }
        let(:product2) { Spree::Product.last }

        it { expect { valid }.to change(Spree::Product, :count).by(2) }

        describe 'create products' do
          before do
            valid
            full_valid_import.reload
          end

          it { expect(full_valid_import.product_ids).to eq Spree::Product.last(2).pluck(:id) }
          it { expect(full_valid_import.products).to eq [product, product2] }
          it { expect(full_valid_import.reload.state).to eq 'completed' }

          describe 'images' do
            let(:product) { Spree::Product.last(2).first }
            let(:product2) { Spree::Product.last }

            let(:image) { product.images.last }
            let(:image2) { product2.images.last }

            it { expect(product.images.count).to eq 1 }
            it { expect(image.attachment_file_name).to eq 'ruby_baseball.png' }

            it { expect(product2.images.count).to eq 1 }
            it { expect(image2.attachment_file_name).to eq 'ror_mug.jpeg' }
          end

          describe 'handles Variants' do
            let(:variant1) { Spree::Variant.last(3).first }
            let(:variant2) { Spree::Variant.last(3).second }

            it { expect(product2.variants.count).to eq 0 }
            it { expect(product.variants.count).to eq 2 }
            it { expect(product.variants.first).to eq variant1 }
            it { expect(product.variants.last).to eq variant2 }
          end
        end

        describe 'handles product properties' do
          subject(:with_properties) { SolidusImportProducts::Import.call(product_imports: imports_with_properties) }

          let(:imports_with_properties) { create(:product_import_with_properties) }
          let(:last_product) { Spree::Product.last }

          before do
            Spree::Property.create name: 'brand', presentation: 'Brand'
          end

          it { expect { with_properties }.to change(Spree::Product, :count).by(1) }

          it do
            with_properties
            expect(last_product.product_properties.map(&:value)).to eq ['Rails']
          end

          it do
            with_properties
            expect(last_product.variants.count).to eq 2
          end
        end

        describe 'handles product taxons' do
          subject(:valid) { SolidusImportProducts::Import.call(product_imports: valid_import) }

          let(:product) { Spree::Product.last }

          it { expect { valid }.to change { Spree::Taxonomy.count }.by 1 }

          it '' do
            valid
            expect(product.taxons.first.name).to eq('Clothing')
          end
        end
      end

      describe 'on invalid csv' do
        subject(:invalid) { SolidusImportProducts::Import.call(product_imports: invalid_import) }

        it { expect { invalid }.to raise_error(SolidusImportProducts::Exception::InvalidPrice) }

        describe 'does not tracks product created ids' do
          before do
            begin
              invalid
            rescue SolidusImportProducts::Exception::InvalidPrice
            end
            invalid_import.reload
          end

          it { expect(invalid_import.product_ids).to be_empty }
          it { expect(invalid_import.products).to be_empty }
          it { expect(invalid_import.reload.state).to eq 'failed' }
          it { expect(Spree::Product.count).to eq 0 }
        end
      end
    end
  end
end
