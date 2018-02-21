require 'spec_helper'

RSpec.describe Spree::ProductImport do
  describe '#user' do
    it { is_expected.to belong_to(:user) }
  end

  describe "#create_variant_for" do
    before do
      product; size; color; option_color; option_size
    end

    let(:product) { create(:product, :sku => "001", :slug => "S0388G-bloch-kids-tap-flexewe") }
    let(:size) { create(:option_type, :name => "tshirt-size") }
    let(:color) { create(:option_type, :name => "tshirt-color", :presentation => "Color") }
    let(:option_color) { create(:option_value, :name => "blue", :presentation => "Blue", :option_type => color) }
    let(:option_size) { create(:option_value, :name => "s", :presentation => "Small", :option_type => size) }

    let(:params) do
      {:sku=>"002", :name=>"S0388G Bloch Kids Tap Flexww", :description=>"Lace Up Split Sole Leather Tap Shoe",
        :cost_price=>"29.25", :price=>"54.46", :available_on=>"1/1/10", :"tshirt-color"=>"Blue", :"tshirt-size"=>"Small",
        :on_hand=>"2", :height=>"3", :width=>"4", :depth=>"9", :weight=>"1", :position=>"0", :category=>"Categories >
        Clothing", :slug=>"S0388G-bloch-kids-tap-flexewe"
      }
    end

    it "creates a new variant when product already exist" do
      product.variants_including_master.count.should == 1
      expect do
        described_class.new.send(:create_variant_for, product, :with => params)
      end.to change(product.variants, :count).by(1)
      product.variants.count.should == 1
      variant = product.variants.last
      variant.price.to_f.should == 54.46
      variant.cost_price.to_f.should == 29.25
      product.option_types.should =~ [size, color]
      variant.option_values.should =~ [option_size, option_color]
    end

    it "creates missing option_values for new variant" do
      described_class.new.send(:create_variant_for, product, :with => params.merge(:"tshirt-size" => "Large", :"tshirt-color" => "Yellow"))
      variant = product.variants.last
      product.option_types.should =~ [size, color]
      variant.option_values.should =~ Spree::OptionValue.where(:name => %w(Large Yellow))
    end

    it "should not duplicate option_values for existing variant" do
      expect do
        described_class.new.send(:create_variant_for, product, :with => params.merge(:"tshirt-size" => "Large", :"tshirt-color" => "Yellow"))
        described_class.new.send(:create_variant_for, product, :with => params.merge(:"tshirt-size" => "Large", :"tshirt-color" => "Yellow"))
      end.to change(product.variants, :count).by(1)
      variant = product.variants.last
      product.option_types.should =~ [size, color]
      variant.option_values.reload.should =~ Spree::OptionValue.where(:name => %w(Large Yellow))
    end

    it "throws an exception when variant with sku exist for another product" do
      other_product = create(:product, :sku => "002")
      expect do
        described_class.new.send(:create_variant_for, product, :with => params.merge(:"tshirt-size" => "Large", :"tshirt-color" => "Yellow"))
      end.to raise_error(Spree::SkuError)
    end
  end

  describe "#import_data!" do
    let(:valid_import) { create(:product_import) }
    let(:invalid_import) { create(:invalid_product_import) }

    context "on valid csv" do
      it "create products successfully" do
        described_class.settings[:variant_comparator_field] = :name
        expect { valid_import.import_data! }.to change(Spree::Product, :count).by(1)
        Spree::Product.last.variants.count.should == 2
      end

      it "tracks product created ids" do
        valid_import.import_data!
        valid_import.reload
        expect(valid_import.product_ids).to eq [Spree::Product.last.id]
        valid_import.products.should == [Spree::Product.last]
      end

      it "handles product properties" do
        Spree::Property.create :name => "brand", :presentation => "Brand"
        import = create(:product_import_with_properties)

        expect {
          import.import_data!(true)
        }.to change(Spree::Product, :count).by(1)

        (product = Spree::Product.last).product_properties.map(&:value).should == ["Rails"]
        product.variants.count.should == 2
      end

      it "sets state to completed" do
        valid_import.import_data!
        valid_import.reload.state.should == "completed"
      end
    end

    context "on invalid csv" do
      it "should not tracks product created ids" do
        expect { invalid_import.import_data! }.to raise_error(Spree::ImportError)
        invalid_import.reload
        invalid_import.product_ids.should be_empty
        invalid_import.products.should be_empty
      end

      context "when params = true (transaction)" do
        it "rollback transation" do
          expect { invalid_import.import_data! }.to raise_error(Spree::ImportError)
          Spree::Product.count.should == 0
        end

        it "sets state to failed" do
          expect { invalid_import.import_data! }.to raise_error(Spree::ImportError)
          invalid_import.reload.state.should == "failed"
        end
      end

      context "when params = false (no transaction)" do
        it "sql are permanent" do
          expect { invalid_import.import_data!(false) }.to raise_error(Spree::ImportError)
          Spree::Product.count.should == 1
        end

        it "sets state to failed" do
          expect { invalid_import.import_data!(false) }.to raise_error(Spree::ImportError)
          invalid_import.reload.state.should == "failed"
        end
      end
    end
  end

  describe "#destroy_products" do
    it "should also destroy associations" do
      import = create(:product_import_with_properties)
      expect {
        import.import_data!(true)
      }.to change(Spree::Product, :count).by(1)
      import.destroy
      Spree::Variant.count.should == 0
    end
  end
end
