# frozen_string_literal: true

Spree::Backend::Config.configure do |config|
  config.menu_items.detect { |menu_item|
    menu_item.label == :products
  }.sections << :product_imports
end

Deface::Override.new(
  virtual_path: 'spree/admin/shared/_product_sub_menu',
  name: 'product_import_admin_sidebar_menu',
  insert_bottom: "[data-hook='admin_product_sub_tabs']",
  partial: 'spree/admin/shared/import_sidebar_menu'
) do
  <<-HTML
    <% if can? :admin, Spree::ProductImport %>
      <%= tab :product_imports, url: spree.admin_product_imports_url %>
    <% end %>
  HTML
end
