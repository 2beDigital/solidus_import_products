Spree::Core::Engine.routes.append do
  namespace :admin do
    resources :product_imports
  end
end
