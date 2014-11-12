Delayed::Worker.logger = Logger.new(Rails.root.join('log', "import_products_#{Rails.env}.log"))
Delayed::Worker.backend = :active_record
