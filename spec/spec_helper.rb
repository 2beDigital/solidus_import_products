require 'simplecov'
RSpec.configure do |config|
  # Run Coverage report
  if config.files_to_run.one?
    config.default_formatter = 'doc'
  else
    SimpleCov.start 'rails' do
      add_group 'Controllers', 'app/controllers'
      add_group 'Helpers', 'app/helpers'
      add_group 'Mailers', 'app/mailers'
      add_group 'Models', 'app/models'
      add_group 'Services', 'app/services'
      add_group 'Views', 'app/views'
      add_group 'Libraries', 'lib'

      add_filter '.bundle'
      #add_filter 'lib/solidus_mercado_pago/version.rb'
    end
  end
end

# This file is copied to ~/spec when you run 'ruby script/generate rspec'
# from the project root directory.
ENV["RAILS_ENV"] ||= 'test'
require File.expand_path("../dummy/config/environment.rb",  __FILE__)

require 'rspec/rails'
require 'ffaker'
require 'capybara/rspec'
require 'devise'

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[File.join(File.dirname(__FILE__), "support/**/*.rb")].each {|f| require f }

# Requires factories defined in spree_core
require 'spree/testing_support/factories'
require 'spree/testing_support/controller_requests'
require 'spree/testing_support/url_helpers'
require 'spree/testing_support/preferences'

RSpec.configure do |config|
  # == Mock Framework
  config.mock_with :rspec

  config.fixture_path = "#{::Rails.root}/spec/fixtures"

  config.infer_spec_type_from_file_location!
  # config.include Devise::TestHelpers, :type => :controller
  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, comment the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = true
  # config.include Solidus::UrlHelpers
  config.include AuthenticationHelpers, type: :feature

  config.include Spree::TestingSupport::UrlHelpers
  config.include Spree::TestingSupport::Preferences
  config.include Spree::TestingSupport::ControllerRequests, type: :controller
  config.include Devise::Test::ControllerHelpers, type: :controller

end
