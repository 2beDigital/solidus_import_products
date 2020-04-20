# frozen_string_literal: true

require 'spec_helper'

# TODO: check variant image

module SolidusImportProducts
  describe CreateVariant do
    describe 'call' do
      subject(:call) { described_class.call(product: product, product_information: product_information) }

      let(:stock_location) { create(:stock_location, default: true) }
      let(:product) { create(:product, name: 'productX', sku: '002', price: 124.10) }
      let(:value1) { create(:option_value, presentation: 'Y') }
      let(:type1) { value1.option_type }
      let(:value2) { create(:option_value, presentation: 'X') }
      let(:type2) { value2.option_type }

      before do
        stock_location
        product
        value1
        value2
        product.option_types << type1
        product.option_types << type2
      end

      describe 'Creation' do
        let(:variant) { call }

        describe 'Basic' do
          let(:product_information) do
            { attributes:
              {
                name: 'productX',
                sku: '002b',
                price: '10.51',
                backorderable: true,
                stock: '99'
              },
              variant_options: {
                type1.name => value1.presentation,
                type2.name => value2.presentation
              },
              variant_images: [],
            }
          end

          it { expect { call }.to change { product.variants.size }.by(1) }
          it { expect(variant.product).to eq product }
          it { expect(variant.price).to eq 10.51 }
          it { expect(variant.sku).to eq '002b' }
          it { expect(variant.is_backorderable?).to be true }
          it { expect(variant.option_values_variants.size).to eq 2 }
          it { expect(variant.option_value(type1.name)).to eq value1.presentation }
          it { expect(variant.option_value(type2.name)).to eq value2.presentation }
          it { expect(variant.total_on_hand).to eq 99 }
        end
        describe 'creates missing option_type and values for new variant' do
          let(:product_information) do
            { attributes:
              {
                name: 'productX',
                sku: '002b',
                price: '10.51'
              },
              variant_options: {
                type1.name => value1.presentation,
                type2.name => 'another presentation',
                'new type' => 'some value'
              },
              variant_images: [] }
          end

          it { expect { call }.to change { product.reload.variants.size }.by(1) }
          it { expect { call }.to change { Spree::OptionType.count }.by(1) }
          it { expect { call }.to change { product.reload.option_types.size }.by(1) }
          it { expect { call }.to change { Spree::OptionValue.count }.by(2) }
          it { expect(variant.option_values_variants.size).to eq 3 }
          it { expect(variant.option_value(type2.name)).to eq 'another presentation' }
          it { expect(variant.option_value('new type')).to eq 'some value' }
        end
        describe 'if price not set, it assigns product price' do
          let(:product_information) do
            { attributes:
              {
                name: 'productX',
                sku: '002b'
              },
              variant_images: [],
              variant_options: {
                type1.name => value1.presentation,
                type2.name => value2.presentation
              } }
          end

          it { expect(variant.price).to eq 124.10 }
        end
      end

      describe 'Update existent variant' do
        describe 'Success' do
          let(:product_information) do
            { attributes:
              {
                name: 'productX',
                sku: '002b',
                stock: 99,
                backorderable: false,
                price: '10.51'
              },
              variant_options: {
                type1.name => value1.presentation,
                type2.name => value2.presentation
              },
              variant_images: [] }
          end
          let(:variant) { create(:variant, product: product, sku: product_information[:attributes][:sku]) }

          before do
            product.option_types << type1
            variant.option_values << value1
          end

          it { expect { call }.not_to change { product.variants.size } }

          it 'do not duplicate option_types for existing variant' do
            expect { call }.to change { product.reload.option_types.size }.by(0)
          end

          it 'do not duplicate option_values for existing variant' do
            expect { call }.to change { variant.reload.option_values.size }.by(1)
          end

          it 'update price' do
            expect { call }.to change { variant.reload.price }.to 10.51
          end

          it 'update stock' do
            expect { call }.to change { variant.reload.total_on_hand }.to 99
          end

          it { expect { call }.to change { variant.reload.is_backorderable? }.to false }
        end

        describe 'Error' do
          describe 'invalid variant' do
            let(:product_information) do
              { attributes:
                {
                  name: 'productX',
                  variant_images: [],
                  price: 'invalid_price'
                },
                type1.name => value1.presentation,
                type2.name => value2.presentation }
            end

            it { expect { call }.to raise_error(SolidusImportProducts::Exception::VariantError) }
          end
          describe 'product SkuError because variant belongs to another product' do
            let(:existent_variant) { create(:variant, sku: '002b') }

            let(:product_information) do
              { attributes:
                {
                  name: 'productX',
                  sku: '002b',
                  price: '10.51'
                },
                variant_images: [],
                variant_options: {
                  type1.name => value1.presentation,
                  type2.name => value2.presentation
                } }
            end

            before { existent_variant }

            it { expect { call }.to raise_error(SolidusImportProducts::Exception::SkuError) }
          end
        end
      end
    end
  end
end
