Spree::Core::Engine.append_routes do
  namespace :admin do
    resources :product_imports
  end
end
