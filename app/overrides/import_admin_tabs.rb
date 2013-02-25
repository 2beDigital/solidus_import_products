# Deface::Override.new(:virtual_path => "spree/layouts/admin",
#                      :name => "import_admin_tabs",
#                      :insert_bottom => "[data-hook='admin_tabs'], #admin_tabs[data-hook]",
#                      :text => "<%= tab(:product_imports, :icon => 'icon-random') %>")

Deface::Override.new(:virtual_path => %q{spree/admin/shared/_configuration_menu},
                     :name => %q{add_faq_configuration_line},
                     :insert_bottom => %q{[data-hook="admin_configurations_sidebar_menu"]},
                     :text => %q{<%= configurations_sidebar_menu_item t(:product_imports), admin_product_imports_url %>},
                     :disabled => false)
