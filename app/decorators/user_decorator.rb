Spree::User.class_eval do

  has_many :product_imports, class_name: 'Spree::ProductImport', foreign_key: 'created_by'
  
end
