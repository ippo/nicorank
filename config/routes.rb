Rails.application.routes.draw do
  get  'day' => 'day#index'
  get  'day/:code(/:date(.:format))'    => 'day#list'
  get  'day/:code/:date/edit'           => 'day#edit'
  get  'day/:code/:date/fix'            => 'day#fix'
  put  'day/:code/:date/:item/editable' => 'day#editable'
  get  'day/:code/:date/conf'            => 'day#conf'
  post 'day/:code/:date/conf'            => 'day#conf'
  get  'day/:code/:date/pass'            => 'day#pass'
  post 'day/:code/:date/pass'            => 'day#pass'

  #get  'day/top'
  #get  'day/index'
  #get  'day/list'
  #get  'day/edit'
  #get  'day/update'
  #get  'day/fix'
  #get  'day/conf'
  #get  'day/pass'
  #get  'day/bbs'
  #put  'day/editable'

  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'
  root 'day#top'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
