# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ImportProductsJob, type: :job do
  include ActiveJob::TestHelper

  describe '#perform_later' do
    subject(:job_now) { described_class.perform_now(products_import) }

    let(:products_import) { create(:product_import) }

    before { create(:store) }

    it { expect { described_class.perform_later(products_import) }.to have_enqueued_job(ImportProductsJob) }

    describe 'perform' do
      it 'call SolidusImportProducts::Import' do
        expect(SolidusImportProducts::Import).to receive(:call).and_return(true)
        job_now
      end

      it 'success' do
        allow(SolidusImportProducts::Import).to receive(:call).and_return(true)

        expect do
          perform_enqueued_jobs { job_now }
        end.to change(Spree::UserMailer.deliveries, :size).by(1)
      end

      it 'error' do
        allow(SolidusImportProducts::Import).to(receive(:call).and_raise { SolidusImportProducts::Exception::ImportError })

        expect do
          perform_enqueued_jobs { job_now }
        end.to change(Spree::UserMailer.deliveries, :size).by(1)
      end
    end
  end
end
