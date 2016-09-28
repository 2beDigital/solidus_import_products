module Solidus
  module UrlHelpers
    def solidus
      Spree::Core::Engine.routes.url_helpers
    end
  end
end