# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Spree::ProductImport do
  describe '#user' do
    it { is_expected.to belong_to(:user) }
  end

  # describe "#create_variant_for" do
  #   before do
  #     product; size; color; option_color; option_size
  #   end
  #
  #   let(:product) { create(:product, :sku => "001", :slug => "S0388G-bloch-kids-tap-flexewe") }
  #   let(:size) { create(:option_type, :name => "tshirt-size") }
  #   let(:color) { create(:option_type, :name => "tshirt-color", :presentation => "Color") }
  #   let(:option_color) { create(:option_value, :name => "blue", :presentation => "Blue", :option_type => color) }
  #   let(:option_size) { create(:option_value, :name => "s", :presentation => "Small", :option_type => size) }
  #
  #   let(:params) do
  #     {:sku=>"002", :name=>"S0388G Bloch Kids Tap Flexww", :description=>"Lace Up Split Sole Leather Tap Shoe",
  #       :cost_price=>"29.25", :price=>"54.46", :available_on=>"1/1/10", :"tshirt-color"=>"Blue", :"tshirt-size"=>"Small",
  #       :on_hand=>"2", :height=>"3", :width=>"4", :depth=>"9", :weight=>"1", :position=>"0", :category=>"Categories >
  #       Clothing", :slug=>"S0388G-bloch-kids-tap-flexewe"
  #     }
  #   end
  #
  #   it "creates a new variant when product already exist" do
  #     product.variants_including_master.count.should == 1
  #     expect do
  #       described_class.new.send(:create_variant_for, product, :with => params)
  #     end.to change(product.variants, :count).by(1)
  #     product.variants.count.should == 1
  #     variant = product.variants.last
  #     variant.price.to_f.should == 54.46
  #     variant.cost_price.to_f.should == 29.25
  #     product.option_types.should =~ [size, color]
  #     variant.option_values.should =~ [option_size, option_color]
  #   end
  #
  #   it "creates missing option_values for new variant" do
  #     described_class.new.send(:create_variant_for, product, :with => params.merge(:"tshirt-size" => "Large", :"tshirt-color" => "Yellow"))
  #     variant = product.variants.last
  #     product.option_types.should =~ [size, color]
  #     variant.option_values.should =~ Spree::OptionValue.where(:name => %w(Large Yellow))
  #   end
  #
  #   it "should not duplicate option_values for existing variant" do
  #     expect do
  #       described_class.new.send(:create_variant_for, product, :with => params.merge(:"tshirt-size" => "Large", :"tshirt-color" => "Yellow"))
  #       described_class.new.send(:create_variant_for, product, :with => params.merge(:"tshirt-size" => "Large", :"tshirt-color" => "Yellow"))
  #     end.to change(product.variants, :count).by(1)
  #     variant = product.variants.last
  #     product.option_types.should =~ [size, color]
  #     variant.option_values.reload.should =~ Spree::OptionValue.where(:name => %w(Large Yellow))
  #   end
  #
  #   it "throws an exception when variant with sku exist for another product" do
  #     other_product = create(:product, :sku => "002")
  #     expect do
  #       described_class.new.send(:create_variant_for, product, :with => params.merge(:"tshirt-size" => "Large", :"tshirt-color" => "Yellow"))
  #     end.to raise_error(Spree::SkuError)
  #   end
  # end
  #

  # describe "#destroy_products" do
  #   it "should also destroy associations" do
  #     import = create(:product_import_with_properties)
  #     expect {
  #       import.import_data!(true)
  #     }.to change(Spree::Product, :count).by(1)
  #     import.destroy
  #     Spree::Variant.count.should == 0
  #   end
  # end
end
