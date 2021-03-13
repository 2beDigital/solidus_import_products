# frozen_string_literal: true

require 'spree/core'

module SolidusImportProducts
  class Engine < Rails::Engine
    include SolidusSupport::EngineExtensions::Decorators

    isolate_namespace Spree

    engine_name 'import_products'

    # use rspec for tests
    config.generators do |g|
      g.test_framework :rspec
    end
  end
end
