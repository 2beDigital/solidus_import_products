# Deface::Override.new(
#   virtual_path: 'spree/layouts/admin',
#   name: 'product_import_admin_sidebar_menu',
#   insert_bottom: '#main-sidebar',
#   partial: 'spree/admin/shared/import_sidebar_menu'
# )

Deface::Override.new(
    virtual_path: "spree/admin/shared/_configuration_menu",
    name: "product_import_admin_sidebar_menu",
    insert_bottom: "[data-hook='admin_configurations_sidebar_menu']",
		text: "<%= configurations_sidebar_menu_item t(:product_imports), spree.admin_product_imports_url %>"
    #partial: 'spree/admin/shared/import_sidebar_menu'
)
