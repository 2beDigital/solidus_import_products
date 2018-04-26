require 'spec_helper'

module SolidusImportProducts
  describe Import do
    describe 'call' do
      let(:valid_import) { create(:product_import) }
      let(:invalid_import) { create(:invalid_product_import) }

      describe 'on valid csv' do
        subject(:valid) { SolidusImportProducts::Import.call(product_imports: valid_import) }

        it { expect { valid }.to change(Spree::Product, :count).by(1) }

        describe 'update object' do
          before do
            valid
            valid_import.reload
          end

          it { expect(Spree::Product.last.variants.count).to eq 2 }
          it { expect(valid_import.product_ids).to eq [Spree::Product.last.id] }
          it { expect(valid_import.products).to eq [Spree::Product.last] }
          it { expect(valid_import.reload.state).to eq 'completed' }

          describe 'images' do
            subject(:product) { Spree::Product.last }
            # TODO: seguir desde aca.
            it { expect(product.images.count).to eq 1 }
          end
        end

        # TODO: Test Variants.
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
