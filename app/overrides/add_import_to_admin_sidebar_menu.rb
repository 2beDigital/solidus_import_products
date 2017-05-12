Deface::Override.new(
    virtual_path: "spree/admin/shared/_product_sub_menu",
    name: "product_import_admin_sidebar_menu",
    insert_bottom: "[data-hook='admin_product_sub_tabs']",
    partial: 'spree/admin/shared/import_sidebar_menu'
)
