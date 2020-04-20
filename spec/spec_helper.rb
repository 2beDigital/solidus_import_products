# frozen_string_literal: true

# Configure Rails Environment
ENV['RAILS_ENV'] = 'test'

# Run Coverage report
require 'solidus_dev_support/rspec/coverage'

require File.expand_path('dummy/config/environment.rb', __dir__)

# Requires factories and other useful helpers defined in spree_core.
require 'solidus_dev_support/rspec/feature_helper'

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[File.join(File.dirname(__FILE__), 'support/**/*.rb')].each { |f| require f }

# Requires factories defined in lib/solidus_reviews/factories.rb
require 'solidus_import_products/factories'

require 'vcr_helper'

RSpec.configure do |config|
  config.use_transactional_fixtures = false
  config.fixture_path = "#{::Rails.root}/spec/fixtures"
  config.infer_spec_type_from_file_location!
  config.use_transactional_fixtures = true
  config.include AuthenticationHelpers, type: :feature
  config.include Devise::Test::ControllerHelpers, type: :controller
end

Spree::ProductImport.settings[:product_image_path] = Rails.root.join('..', 'fixtures', 'images')

#RSpec.configure do |config|
#  # Run Coverage report
#  if config.files_to_run.one?
#    config.default_formatter = 'doc'
#  else
#      add_group 'Controllers', 'app/controllers'
#      add_group 'Helpers', 'app/helpers'
#      add_group 'Mailers', 'app/mailers'
#      add_group 'Models', 'app/models'
#      add_group 'Services', 'app/services'
#      add_group 'Views', 'app/views'
#      add_group 'Libraries', 'lib'
#
#      add_filter '.bundle'
#      add_filter 'lib/generators/solidus_import_products/install/templates/config/initializers/solidus_import_product_settings.rb'
#    end
#  end
#end
#
## This file is copied to ~/spec when you run 'ruby script/generate rspec'
## from the project root directory.
#ENV['RAILS_ENV'] ||= 'test'
#require File.expand_path('../dummy/config/environment.rb', __FILE__)
#
#require 'rspec/rails'
#require 'ffaker'
#require 'capybara/rspec'
#require 'devise'
#require 'vcr_helper'
#
## Requires supporting ruby files with custom matchers and macros, etc,
## in spec/support/ and its subdirectories.
#Dir[File.join(File.dirname(__FILE__), 'support/**/*.rb')].each { |f| require f }
#
#Spree::ProductImport.settings[:product_image_path] = Rails.root.join('..', 'fixtures', 'images')
#
## "#{Rails.root}/../fixtures/images/"
#
## Requires factories defined in spree_core
#require 'spree/testing_support/factories'
#require 'spree/testing_support/controller_requests'
#require 'spree/testing_support/url_helpers'
#require 'spree/testing_support/preferences'
#
#RSpec.configure do |config|
#  # == Mock Framework
#  config.mock_with :rspec
#
#  config.fixture_path = "#{::Rails.root}/spec/fixtures"
#
#  config.infer_spec_type_from_file_location!
#  # config.include Devise::TestHelpers, :type => :controller
#  # If you're not using ActiveRecord, or you'd prefer not to run each of your
#  # examples within a transaction, comment the following line or assign false
#  # instead of true.
#  config.use_transactional_fixtures = true
#  # config.include Solidus::UrlHelpers
#  config.include AuthenticationHelpers, type: :feature
#
#  config.include Devise::Test::ControllerHelpers, type: :controller
#end
