require 'spec_helper'

RSpec.describe ImportProductsJob, type: :job do
  include ActiveJob::TestHelper

  describe '#perform_later' do
    subject(:job_now) { described_class.perform_now(products_import) }

    let(:products_import) { create(:product_import) }

    before { create(:store) }

    it { expect { described_class.perform_later(products_import) }.to have_enqueued_job(ImportProductsJob) }

    describe 'perform' do
      it 'call import_products!' do
        expect_any_instance_of(Spree::ProductImport).to receive(:import_data!).with(true).and_return(true)
        job_now
      end

      it 'success' do
        allow_any_instance_of(Spree::ProductImport).to receive(:import_data!).with(true).and_return(true)

        expect do
          perform_enqueued_jobs { job_now }
        end.to change(Spree::UserMailer.deliveries, :size).by(1)
      end

      it 'error' do
        allow_any_instance_of(Spree::ProductImport).to receive(:import_data!).with(true).and_raise { Spree::ImportError }

        expect do
          perform_enqueued_jobs { job_now }
        end.to change(Spree::UserMailer.deliveries, :size).by(1)
      end

    end
  end
end
