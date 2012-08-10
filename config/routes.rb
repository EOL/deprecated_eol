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

  resources :tasks, :task_states, :task_names, :feed_items, :random_images
  resources :recent_activities, :only => [:index]
  resources :classifications, :only => [:create]
  resources :contacts, :only => [:index, :create, :new]
  resources :collection_items, :only => [:create, :edit, :update]
  resources :comments, :only => [:create, :edit, :update, :destroy]
  resources :sessions, :only => [:new, :create, :destroy]
  resources :wikipedia_imports, :only => [:new, :create] # Curator tool to request import of wikipedia pages

  # Taxa nested resources with pages as alias... this is quite large, sorry.
  resources :pages, :only => [:show], :controller => 'taxa', :as => 'taxa' do
    member do
      get 'overview'
      get 'maps', :controller => 'taxa/maps'
    end
    resource :tree, :only => [:show], :controller => 'taxa/trees'
    resources :media, :only => [:show], :controller => 'taxa/media'
    resources :details, :except => [:show], :controller => 'taxa/details'
    resources :maps, :only => [:show], :controller => 'taxa/maps'
    resources :worklist, :only => [:show], :controller => 'taxa/worklist'
    resources :data_objects, :only => [:create, :new]
    resources :hierarchy_entries, :as => 'entries', :only => [:show] do
      member do
        put 'switch'
        get 'overview'
        get 'maps', :controller => 'taxa/maps'
      end
      resources :tree, :only => [:show], :controller => 'taxa/trees'
      resources :media, :only => [:index], :controller => 'taxa/media'
      resources :details, :only => [:index], :controller => 'taxa/details'
      resources :communities, :as => :community, :controller => 'taxa/communities', :only => [:index] do
        collection do
          get 'collections'
          get 'curators'
        end
      end
      resources :names, :only => [:index, :create, :update], :controller => 'taxa/names' do
        collection do
          get 'common_names'
          get 'related_names'
          get 'synonyms'
        end
        member do
          get 'vet_common_name'
        end
      end
      resources :literature, :only => [:index], :controller => 'taxa/literature' do
        collection do
          get 'bhl'
        end
      end
      resources :resources, :only => [:show], :controller => 'taxa/resources' do
        collection do
          get 'identification_resources'
          get 'education'
          get 'nucleotide_sequences'
          get 'biomedical_terms'
          get 'citizen_science'
        end
      end
      resources :updates, :only => [:index], :controller => 'taxa/updates' do
        member do
          get 'statistics'
        end
      end
    end
    resources :media, :only => [:index], :controller => 'taxa/media' do
      collection do
        get 'set_as_exemplar'
        post 'set_as_exemplar'
      end
    end
    resources :names, :only => [:index, :create, :update], :controller => 'taxa/names' do
      collection do
        get 'common_names'
        get 'related_names'
        get 'synonyms'
        get 'delete'
      end
      member do
        get 'vet_common_name'
      end
    end
    resources :literature, :only => [:index], :controller => 'taxa/literature' do
      collection do
        get 'bhl'
      end
    end
    resources :resources, :controller => 'taxa/resources', :only => [:index] do
      collection do
        get 'identification_resources'
        get 'education'
        get 'nucleotide_sequences'
        get 'biomedical_terms'
        get 'citizen_science'
      end
    end
    resources :communities, :as => :community, :controller => 'taxa/communities', :only => [:index] do
      collection do
        get 'collections'
        get 'curators'
      end
    end
    resources :updates, :only => [:index], :controller => 'taxa/updates' do
      member do
        get 'statistics'
      end
    end
  end

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

  resources :data_objects, :only => [:show, :edit, :update] do
    member do
      put 'curate'
      get 'curation'
      get 'attribution'
      get 'rate'
    end
    resources :comments
  end

  resources :eol_statistics, :as => 'statistics', :only => [:index] do
    collection do
      get 'content_partners'
      get 'curators'
      get 'data_objects'
      get 'lifedesks'
      get 'marine'
      get 'page_richness'
      get 'users_data_objects'
    end
  end

  resources :admin, :only => [:show] do
    resources :content_pages do
      member do
        post 'move_up'
        post 'move_down'
      end
      resources :children, :only => [:new, :create]
      resources :translated_content_pages, :as => :translations, :except => [:show, :index]
    end
    resources :content_partners, :only => [:index] do
      collection do
        get 'notifications'
        post 'notifications'
        get 'statistics'
        post 'statistics'
      end
    end
    resources :eol_statistics, :as => 'statistics', :only => [:index] do
      collection do
        get 'content_partners'
        get 'data_objects'
        get 'marine'
        get 'curators'
        get 'page_richness'
        get 'users_data_objects'
        get 'lifedesks'
      end
    end
  end

  # Old V1 admin search logs:
  resources :search_logs, :controller => 'administrator/search_logs'

  # Facebook integration
  resources :facebook, :only => [:index] do
    collection do
      get 'channel'
    end
  end

  # Miscellaneous named routes:
  match '/activity_logs/find/:id' => 'feeds#find', :as => 'find_feed'
  match '/contact_us' => 'contacts#new', :as => 'contact_us'
  match '/loggertest' => 'content#loggertest' # This is used for configuring logs and log levels.
  match '/boom' => 'content#boom'

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
  match '/data_objects/:id/ignore' => 'data_objects#ignore', :as => 'data_object_ignore'
  match '/data_objects/:id/add_association' => 'data_objects#add_association', :as => 'add_association'
  match '/data_objects/:id/save_association/:hierarchy_entry_id' => 'data_objects#save_association',
    :as => 'save_association'
  match '/data_objects/:id/remove_association/:hierarchy_entry_id' => 'data_objects#remove_association',
    :as => 'remove_association'

  # Named taxon routes:
  match '/pages/:id/literature/bhl_title/:title_item_id' => 'taxa/literature#bhl_title', :as => 'bhl_title'
  match '/pages/:id/entries/:hierarchy_entry_id/literature/bhl_title/:title_item_id' => 'taxa/literature#bhl_title',
    :as => 'entry_bhl_title'

  # Named content page routes:
  match '/help' => 'content#show', :defaults => {:id => 'help'}, :as => 'help'
  match '/about' => 'content#show', :defaults => {:id => 'about'}, :as => 'about'
  match '/news' => 'content#show', :defaults => {:id => 'news'}, :as => 'news'
  match '/discover' => 'content#show', :defaults => {:id => 'discover'}, :as => 'discover'
  match '/contact' => 'content#show', :defaults => {:id => 'contact'}, :as => 'contact'
  match '/terms_of_use' => 'content#show', :defaults => {:id => 'terms_of_use'}, :as => 'terms_of_use'
  match '/citing' => 'content#show', :defaults => {:id => 'citing'}, :as => 'citing'
  match '/privacy' => 'content#show', :defaults => {:id => 'privacy'}, :as => 'privacy'
  match '/curators' => 'content#show', :defaults => {:id => 'curators'}, :as => 'curators'
  match '/curators/*ignore' => 'content#show', :defaults => {:id => 'curators'}
  match '/info/:id' => 'content#show', :as => 'cms_page'
  match '/info/*crumbs' => 'content#show', :as => 'cms_crumbs'

  # Named collection routes:
  # NOTE - Not nesting collection_items under collections: creation is complex, plus edit only used for non-JS users
  match '/collections/:id/:filter' => 'collections#show', :as => 'filtered_collection'

  # Named user routes:
  # NOTE - can't add dynamic segment to a member in rails 2.3 so we have to specify named routes for the following:
  # TODO - can we do this now that we're rails 3?
  match '/users/:user_id/verify/:validation_code' => 'users#verify', :as => 'verify_user'
  match '/users/:user_id/temporary_login/:recover_account_token' => 'users#temporary_login',
    :as => 'temporary_login_user'

  # Old V1 /admin and /administrator namespaces (controllers)
  match 'administrator' => 'admin#index', :as => 'administrator'
  match 'administrator/reports' => 'administrator/reports#index'
  match 'administrator/reports/:action' => 'administrator/reports'
  match 'administrator/curator' => 'administrator/curator#index'
  match 'administrator/translation_log' => 'administrator/translation_log#index'

  # Named API Routes:
  match 'api' => 'api/docs#index' # Default is actually the documenation
  # not sure why this didn't work in some places - but this is for documentation
  match 'api/docs/:action' => 'api/docs'
  # ping is a bit of an exception - it doesn't get versioned and takes no ID
  match 'api/:action' => 'api', :format => 'xml'
  match 'api/:action/:version' => 'api', :version => /[0-1]\.[0-9]/, :format => 'xml'
  # if version is left out we'll set the default to the latest version in the controller
  match 'api/:action/:id' => 'api', :format => 'xml'
  # looks for version, ID
  match 'api/:action/:version/:id' => 'api', :version => /[0-1]\.[0-9]/, :format => 'xml'

  # These are expensive and broad and should be kept at the bottom of the file:
  match '/:id' => 'pages#show', :id => /\d+/
  match '/:q' => 'search#index', :q => /[A-Za-z% ][A-Za-z0-9% ]*/

  # NOTE - I *removed* the default routes.  We shouldn't need them anymore.

  mount Ckeditor::Engine => "/ckeditor" # Required for rich-text editing.

end
