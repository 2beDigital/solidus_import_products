require 'spec_helper'
include ActiveJob::TestHelper

describe 'Import products', type: :feature do

  before do
    create(:store)
    sign_in_as! create(:admin_user)
  end

  it 'admin should be able to import products and delete import' do
    visit spree.admin_product_imports_path
    attach_file('product_import_data_file', File.join(File.dirname(__FILE__), '..', 'fixtures', 'valid.csv'))
    fill_in('separatorChar', with: ',')

    perform_enqueued_jobs do
      click_button I18n.t('spree.actions.import')
    end

    expect(page).to have_content('valid.csv')
    expect(page).to have_content('Thanks, your import has been added to the queue for processing. You will receive an email confirming the import once it has completed')

    # should have created the product
    visit spree.admin_products_path
    expect(page).to have_content('Bloch Kids Tap Flexww')

    visit spree.admin_product_imports_path
    expect(page).to have_content('valid.csv')
    expect(page).to have_content('Completed')

    click_link I18n.t('spree.actions.edit')
    expect(page).to have_content('Bloch Kids Tap Flexww')

    click_button 'Delete'
    expect(page).to have_content('Import and products associated deleted successfully')
    expect(page).not_to have_content('valid.csv')

    # should have deleted product created by import
    visit spree.admin_products_path
    expect(page).not_to have_content('Bloch Kids Tap Flexww')
  end
end
