require 'spec_helper'

module SolidusImportProducts
  describe CreateVariant do
    describe 'call' do
      subject(:call) { described_class.call(product: product, product_information: product_information) }

      let(:product) { create(:product, name: 'productX', sku: '002') }
      let(:value1) { create(:option_value, presentation: 'Y') }
      let(:type1) { value1.option_type }
      let(:value2) { create(:option_value, presentation: 'X') }
      let(:type2) { value2.option_type }

      before do
        product
        value1
        value2
      end

      describe 'Creation' do
        let(:variant) { call }

        describe 'Basic' do
          let(:product_information) do
            { name: 'productX',
              sku: '002b',
              type1.name => value1.presentation,
              type2.name => value2.presentation,
              price: '10.51' }
          end

          it { expect { call }.to change { product.variants.size }.by(1) }
          it { expect(variant.product).to eq product }
          it { expect(variant.price).to eq 10.51 }
          it { expect(variant.sku).to eq '002b' }
          it { expect(variant.option_values_variants.size).to eq 2 }
          it { expect(variant.option_value(type1.name)).to eq value1.presentation }
          it { expect(variant.option_value(type2.name)).to eq value2.presentation }
          it 'set stock'
        end
        it 'creates missing option_values for new variant'
      end

      describe 'Update existent variant' do
        describe 'Success' do
          it 'do not duplicate option_values for existing variant'
          it 'update price'
          it 'update stock'
        end

        describe 'product SkuError because variant belongs to another product' do
          let(:existent_variant) { create(:variant, sku: '002b') }

          let(:product_information) do
            { name: 'productX',
              sku: '002b',
              type1.name => value1.presentation,
              type2.name => value2.presentation,
              price: '10.51' }
          end

          before { existent_variant }

          it { expect { call }.to raise_error(SolidusImportProducts::Exception::SkuError) }
        end
      end
    end
  end
end
