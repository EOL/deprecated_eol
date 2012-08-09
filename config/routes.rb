# first created -> highest priority.
EolUpgrade::Application.routes.draw do

  # Root should be first, since it's most frequently used and should return quickly:
  root :to => 'content#index'

  # Permanent redirects should be second in routes file (according to whom? -- I can't corroborate this).
  match "/podcast" => redirect('http://education.eol.org/podcast')
  match '/pages/:taxon_id/curators' => redirect("/pages/%{taxon_id}/community/curators")
  match '/pages/:taxon_id/images' => redirect("/pages/%{taxon_id}/media")
  match '/pages/:taxon_id/classification_attribution' => redirect("/pages/%{taxon_id}/names")
  match '/taxa/content/:taxon_id' => redirect("/pages/%{taxon_id}/details")
  match '/taxa/images/:taxon_id' => redirect("/pages/%{taxon_id}/media")
  match '/taxa/maps/:taxon_id' => redirect("/pages/%{taxon_id}/maps")
  match '/settings' => redirect("/")
  match '/account/show/:user_id' => redirect("/users/%{user_id}")
  match '/users/forgot_password' => redirect("/users/recover_account")
  match '/users/:user_id/reset_password/:recover_account_token' => redirect("/users/recover_account")
  match '/info/xrayvision' => redirect("/collections/14770")
  match '/info/naturesbest2011' =>  redirect("/collections/19338")
  match '/index' => redirect('/')
  match '/home.html' => redirect('/')

  # Miscellaneous named routes:
  match '/activity_logs/find/:id' => 'feeds#find', :as => 'find_feed'
  match '/contact_us' => 'contacts#new', :as => 'contact_us'

  # Named application routes:
  match '/set_language' => 'application#set_language', :as => 'set_language'
  match '/external_link' => 'application#external_link', :as => 'external_link'

  # Named content routes:
  match '/preview' => 'content#preview', :as => 'preview'
  match '/clear_caches' => 'content#clear_caches', :as => 'clear_caches'
  match '/expire_all' => 'content#expire_all', :as => 'expire_all'
  match '/expire/:id' => 'content#expire_single', :id => /\w+/, :as => 'expire'
  match '/expire_taxon/:id' => 'content#expire_taxon', :id => /\d+/, :as => 'expire_taxon'
  match '/expire_taxa/:id' => 'content#expire_multiple', :id => /\d+/, :as => 'expire_taxa'
  match '/donate' => 'content#donate', :as => 'donate'
  match '/language' => 'content#language', :as => 'language'

  # Search (note there is more search at the end of the file; it is expensive):
  match '/search/:q' => 'search#index', :as => 'search'
  match '/found/:id' => 'taxa#show', :as => 'found'

  # Named session routes (see also resources):
  match '/login' => 'sessions#new', :as => 'login'
  match '/logout' => 'sessions#destroy', :as => 'logout'

  # Named curation routes:
  match '/pages/:taxon_id/details/:data_object_id/set_article_as_exemplar' => 'taxa/details#set_article_as_exemplar',
    :as => 'set_article_as_exemplar'
  match '/pages/:id/worklist/data_objects/:data_object_id' => 'taxa/worklist#data_objects',
    :as => 'taxon_worklist_data_object'

  # Named taxon routes:
  match '/pages/:id/literature/bhl_title/:title_item_id' => 'taxa/literature#bhl_title', :as => 'bhl_title'
  match '/pages/:id/entries/:hierarchy_entry_id/literature/bhl_title/:title_item_id' => 'taxa/literature#bhl_title',
    :as => 'entry_bhl_title'

  # Named content page routes:
  match '/help' => 'content#show', :defaults => {:id => 'help'}, :as => 'help'
  match '/about' => 'content#show', :defaults => {:id => 'about'}, :as => 'about'
  match '/news' => 'content#show', :defaults => {:id => 'news'}, :as => 'news'
  match '/discover' => 'content#show', :defaults => {:id => 'discover'}, :as => 'explore_biodiversity'
  match '/contact' => 'content#show', :defaults => {:id => 'contact'}, :as => 'contact'
  match '/terms_of_use' => 'content#show', :defaults => {:id => 'terms_of_use'}, :as => 'terms_of_use'
  match '/citing' => 'content#show', :defaults => {:id => 'citing'}, :as => 'citing'
  match '/privacy' => 'content#show', :defaults => {:id => 'privacy'}, :as => 'privacy'
  match '/curators/*ignore' => 'content#show', :defaults => {:id => 'curators'}, :as => 'curators'
  match '/info/:id' => 'content#show', :as => 'cms_page'
  match '/info/*crumbs' => 'content#show', :as => 'cms_crumbs'

  # Named collection routes:
  # NOTE - Not nesting collection_items under collections: creation is complex, plus edit only used for non-JS users
  match 'collections/:id/:filter' => 'collections#show', :as => 'filtered_collection'

  # Named user routes:
  # NOTE - can't add dynamic segment to a member in rails 2.3 so we have to specify named routes for the following:
  # TODO - can we do this now that we're rails 3?
  match '/users/:user_id/verify/:validation_code' => 'users#verify', :as => 'verify_user'
  match 'users/:user_id/temporary_login/:recover_account_token' => 'users#temporary_login',
    :as => 'temporary_login_user'

  resources :tasks, :task_states, :task_names, :feed_items, :random_images
  resources :recent_activities, :only => [:index]
  resources :classifications, :only => [:create]
  resources :contacts, :only => [:index, :create, :new]
  resources :collection_items, :only => [:create, :edit, :update]
  resources :comments, :only => [:create, :edit, :update, :destroy]
  resources :sessions, :only => [:new, :create, :destroy]
  resources :wikipedia_imports, :only => [:new, :create] # Curator tool to request import of wikipedia pages

  # Communities nested resources
  # TODO - these member methods want to be :put. Capybara always uses :get, so in the interests of simple tests:
  resources :communities, :except => [:index] do
    collection do
      get 'choose'
      put 'make_editors'
    end
    member do
      get 'join'
      get 'leave'
      get 'delete'
      put 'make_editor'
      get 'revoke_editor'
    end
    resources :newsfeed, :only => [:show]
    resources :collections
    resources :members do
      member do
        # TODO - these shouldn't be GETs, but I really want them to be links, not forms, sooooo...
        get 'grant_manager'
        get 'revoke_manager'
      end
    end
  end

  resources :collections do
    member do
      get 'choose'
    end
    collection do
      get 'choose_collect_target'
      get 'choose_editor_target'
      post 'collect_item'
    end
    resources :newsfeed, :only => [:show]
    resources :editors, :only => [:show]
    resources :inaturalist, :only => [:show]
  end

  resources :content_partners do
    resources :content_partner_contacts, :as => 'contacts', :except => [:index, :show]
    resources :content_partner_agreements, :as => 'agreements', :except => [:index, :destroy]
    resources :statistics, :only => [:show]
    resources :resources do
      member do
        get 'force_harvest'
        post 'force_harvest'
      end
      resources :harvest_events, :only => [:index, :update]
      resources :hierarchies, :only => [:edit, :update] do
        member do
          post 'request_publish'
        end
      end
    end
  end

  resources :users, :path_names => { :new => :register } do
    member do
      get 'terms_agreement'
      post 'terms_agreement'
      get 'pending'
      get 'activated'
      get 'curation_privileges'
      put 'make_editor'
      get 'revoke_editor'
      get 'pending_notifications'
    end
    collection do
      get 'usernames'
      get 'recover_account'
      get 'verify_open_authentication'
    end
    resources :newsfeed, :only => [:show] do
      collection do
        get 'comments'
      end
    end
    resources :notification, :only => [:edit, :update]
    resources :activity, :only => [:show]
    resources :collections, :only => [:index]
    resources :communities, :only => [:index]
    resources :content_partners, :only => [:index]
    resources :open_authentications, :only => [:index, :new, :update, :destroy]
  end

#   # TODO - the curate member method is not working when you use the url_for method and its derivatives.  Instead, the default
#   # url of "/data_objects/curate/:id" works.  Not sure why.
#   map.resources :data_objects, :only => [:show, :edit, :update], :member => { :curate => :put, :curation => :get, :attribution => :get, :rate => :get } do |data_objects|
#     data_objects.resources :comments
#     data_objects.resources :tags,  :collection => { :public => :get, :private => :get, :add_category => :post,
#                                                     :autocomplete_for_tag_key => :get },
#                                    :member => { :autocomplete_for_tag_value => :get }
#   end
#   map.data_object_ignore 'data_objects/:id/ignore', :controller => 'data_objects', :action => 'ignore'
#   map.add_association 'data_objects/:id/add_association', :controller => 'data_objects', :action => 'add_association'
#   map.save_association 'data_objects/:id/save_association/:hierarchy_entry_id', :controller => 'data_objects', :action => 'save_association'
#   map.remove_association 'data_objects/:id/remove_association/:hierarchy_entry_id', :controller => 'data_objects', :action => 'remove_association'
# 
#   map.resources :tags, :collection => { :search => :get }
# 
#   map.connect 'loggertest', :controller => 'content', :action => 'loggertest' # This is used for configuring logs and log levels.
#   map.connect 'boom', :controller => 'content', :action => 'boom'
# 
#   # Taxa nested resources with pages as alias
#   map.resources :taxa, :only => [:show], :as => :pages do |taxa|
#     taxa.resources :hierarchy_entries, :as => :entries, :only => [:show], :member => { :switch => [:put] } do |entries|
#       entries.resource :tree, :only => [:show], :controller => "taxa/trees"
#       entries.resource :overview, :only => [:show], :controller => "taxa/overviews"
#       entries.resources :media, :only => [:index], :controller => "taxa/media"
#       entries.resources :details, :only => [:index], :controller => "taxa/details"
#       entries.resources :communities, :as => :community, :only => [:index], :controller => "taxa/communities",
#         :collection => { :collections => :get, :curators => :get }
#       entries.resources :names, :only => [:index, :create, :update], :controller => "taxa/names",
#                                 :collection => { :common_names => :get, :related_names => :get, :synonyms => :get },
#                                 :member => { :vet_common_name => :get }
#       entries.resource :literature, :only => [:show], :controller => "taxa/literature",
#         :member => { :bhl => :get }
#       entries.resource :resources, :only => [:show], :controller => "taxa/resources",
#         :member => { :identification_resources => :get, :education => :get , :nucleotide_sequences => :get, :biomedical_terms => :get,
#           :citizen_science => :get }
#       entries.resource :maps, :only => [:show], :controller => "taxa/maps"
#       entries.resource :updates, :only => [:show], :controller => "taxa/updates",
#         :member => { :statistics => :get }
#     end
#     taxa.resource :tree, :only => [:show], :controller => "taxa/trees"
#     taxa.resource :overview, :only => [:show], :controller => "taxa/overviews"
#     taxa.resources :media, :only => [:index], :controller => "taxa/media",
#                            :collection => { :set_as_exemplar => [:get, :post] }
#     taxa.resources :details, :except => [:show], :controller => "taxa/details"
#     taxa.resources :names, :only => [:index, :create, :update], :controller => "taxa/names",
#                           :collection => { :common_names => :get, :related_names => :get,
#                                            :synonyms => :get, :delete => :get },
#                           :member => { :vet_common_name => :get }
#     taxa.resource :literature, :only => [:show], :controller => "taxa/literature",
#       :member => { :bhl => :get }
#     taxa.resource :resources, :only => [:show], :controller => "taxa/resources",
#       :member => { :identification_resources => :get, :education => :get , :nucleotide_sequences => :get , :biomedical_terms => :get,
#         :citizen_science => :get }
#     taxa.resources :communities, :as => :community, :only => [:index], :controller => "taxa/communities",
#        :collection => { :collections => :get, :curators => :get }
#     taxa.resource :maps, :only => [:show], :controller => "taxa/maps"
#     taxa.resource :updates, :only => [:show], :controller => "taxa/updates",
#       :member => { :statistics => :get }
#     taxa.resource :worklist, :only => [:show], :controller => "taxa/worklist"
#     taxa.resources :data_objects, :only => [:create, :new], :controller => 'data_objects'
#   end
#
#   map.resources :eol_statistics, :as => 'statistics', :only => [:index],
#                                  :collection => { :content_partners => [:get],
#                                                   :curators => [:get],
#                                                   :data_objects => [:get],
#                                                   :lifedesks => [:get],
#                                                   :marine => [:get],
#                                                   :page_richness => [:get],
#                                                   :users_data_objects => [:get] }
# 
#   # New V2 /admins namespace with singular resource admin
#   map.resource :admin, :only => [:show] do |admin|
#     admin.resources :content_pages, :member => {:move_up => :post, :move_down => :post}, :namespace => 'admins/' do |content_page|
#       content_page.resources :children, :only => [:new, :create], :controller => 'content_pages'
#       content_page.resources :translated_content_pages, :as => :translations, :except => [:show, :index], :controller => 'translated_content_pages'
#     end
#     admin.resources :content_partners, :collection => {:notifications => [:get, :post], :statistics => [:get, :post]},
#                                        :only => [:index], :namespace => 'admins/'
#     admin.resources :eol_statistics, :as => 'statistics', :only => [:index],
#                                      :collection => {:content_partners => [:get],
#                                                  :data_objects => [:get],
#                                                  :marine => [:get],
#                                                  :curators => [:get],
#                                                  :page_richness => [:get],
#                                                  :users_data_objects => [:get],
#                                                  :lifedesks => [:get]},
#                                      :namespace => 'admins/'
#   end
# 
#   # Old V1 /admin and /administrator namespaces (controllers)
#   map.administrator 'administrator',           :controller => 'admin',           :action => 'index'
#   map.connect 'administrator/reports',         :controller => 'administrator/reports', :action => 'index'
#   map.connect 'administrator/reports/:action', :controller => 'administrator/reports'
#   #map.connect 'administrator/user_data_object',    :controller => 'administrator/user_data_object', :action => 'index'
#   # map.connect 'administrator/reports/:report', :controller => 'administrator/reports', :action => 'catch_all',
#   #                                              :requirements => { :report => /.*/ }
#   map.connect 'administrator/curator', :controller => 'administrator/curator', :action => 'index'
#   map.connect 'administrator/translation_log', :controller => 'administrator/translation_log', :action => 'index'
#   map.resources :search_logs, :controller => 'administrator/search_logs'
# 
#   # TODO = make this resourceful, dammit - are these now obsolete?
#   map.connect '/taxon_concepts/:taxon_concept_id/comments/', :controller => 'comments', :action => 'index',
#                                                              :conditions => {:method => :get}
#   map.connect '/taxon_concepts/:taxon_concept_id/comments/', :controller => 'comments', :action => 'create',
#                                                              :conditions => {:method => :post}
# 
#   # by default /api goes to the docs
#   map.connect 'api', :controller => 'api/docs', :action => 'index'
#   # not sure why this didn't work in some places - but this is for documentation
#   map.connect 'api/docs/:action', :controller => 'api/docs'
#   # ping is a bit of an exception - it doesn't get versioned and takes no ID
#   map.connect 'api/:action', :controller => 'api'
#   map.connect 'api/:action.:format', :controller => 'api'
#   map.connect 'api/:action/:version', :controller => 'api', :version => /[0-1]\.[0-9]/
#   map.connect 'api/:action/:version.:format', :controller => 'api', :version => /[0-1]\.[0-9]/
#   # if version is left out we'll set the default to the latest version in the controller
#   map.connect 'api/:action/:id', :controller => 'api'
#   map.connect 'api/:action/:id.:format', :controller => 'api'
#   # looks for version, ID and format
#   map.connect 'api/:action/:version/:id', :controller => 'api', :version => /[0-1]\.[0-9]/
#   map.connect 'api/:action/:version/:id.:format', :controller => 'api', :version => /[0-1]\.[0-9]/


  # Facebook integration
  resources :facebook, :only => [:index] do
    collection do
      get 'channel'
    end
  end

  # These are expensive and broad and should be kept at the bottom of the file:
  match ':id' => 'pages#show', :id => /\d+/
  match ':q' => 'search#index', :q => /[A-Za-z% ][A-Za-z0-9% ]*/

  # NOTE - I *removed* the default routes.  We shouldn't need them anymore.

  mount Ckeditor::Engine => "/ckeditor" # Required for rich-text editing.

end
