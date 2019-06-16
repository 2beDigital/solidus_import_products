# frozen_string_literal: true

Deface::Override.new(virtual_path: "spree/admin/product_imports/index",
                     name: "import_products_link_sample",
                     insert_after: "[data-hook='buttons']",
                     partial: "spree/admin/shared/import_products_link_sample",
                     disabled: false)
