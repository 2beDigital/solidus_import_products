# frozen_string_literal: true

module Spree
  module PermissionSets
    module ProductManagementDecorator
      # Self prepend to extend feature at the class level
      def self.prepended(base)
        base.class_eval do
          # Create an alias_method for the original activate! method as we need to execute it as it is
          alias_method :super_activate!, :activate!
        end
      end

      # Extends the behaviour of the activate! method by calling the original method and adding an extra permission set for Spree::ProductImport
      def activate!
        super_activate!
        can :manage, Spree::ProductImport
      end

      ::Spree::PermissionSets::ProductManagement.prepend self
    end
  end
end
