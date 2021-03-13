# frozen_string_literal: true

module Spree
  module UserDecorator
    def self.prepended(base)
      base.class_eval do
        has_many :product_imports, class_name: 'Spree::ProductImport', foreign_key: 'created_by'
      end
    end

    ::Spree.user_class.prepend self
  end
end
