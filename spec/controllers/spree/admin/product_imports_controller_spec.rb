# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Spree::Admin::ProductImportsController, type: :controller do
  let(:user) { create(:admin_user) }

  before do
    sign_in user
  end

  describe 'POST create' do
    subject(:post_create) do
      post  :create,
            params: {
              product_import: {
                separatorChar: ',',
                data_file: Rack::Test::UploadedFile.new(Rails.root.join('..', 'fixtures', 'valid.csv')),
                compress_image_file: Rack::Test::UploadedFile.new(Rails.root.join('..', 'fixtures', 'images.zip')),
                encoding_csv: 'UTF-8'
              }
            }
    end

    it { expect { post_create }.to change { user.product_imports.count }.by(1) }
    it { expect { post_create }.to have_enqueued_job(ImportProductsJob) }
    it { is_expected.to redirect_to(admin_product_imports_path) }
  end
end
