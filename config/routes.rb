# first created -> highest priority.
Eol::Application.routes.draw do

  # Root should be first, since it's most frequently used and should return quickly:
  root :to => 'content#index'

  #resque
  mount Resque::Server.new, at: "/resque"
  # Permanent redirects. Position them before any routes they take precedence over.
  match '/podcast' => redirect('http://podcast.eol.org/podcast')
  match '/pages/:taxon_id/curators' => redirect("/pages/%{taxon_id}/community/curators")
  match '/pages/:taxon_id/images' => redirect("/pages/%{taxon_id}/media")
  match '/pages/:taxon_id/classification_attribution' => redirect("/pages/%{taxon_id}/names")
  match '/pages/:taxon_id/entries/:entry_id' => redirect("/pages/%{taxon_id}/hierarchy_entries/%{entry_id}/overview")
  match '/pages/:taxon_id/entries/:entry_id/overview' => redirect("/pages/%{taxon_id}/hierarchy_entries/%{entry_id}/overview")
  match '/pages/:taxon_id/entries/:entry_id/details' => redirect("/pages/%{taxon_id}/hierarchy_entries/%{entry_id}/details")
  match '/pages/:taxon_id/classification_attribution' => redirect("/pages/%{taxon_id}/names")
  match '/pages/:taxon_id/community' => redirect("/pages/%{taxon_id}/communities")
  match '/pages/:taxon_id/community/collections' => redirect("/pages/%{taxon_id}/communities/collections")
  match '/pages/:taxon_id/community/curators' => redirect("/pages/%{taxon_id}/communities/curators")
  match '/pages/:taxon_id/hierarchy_entries/:entry_id/community' => redirect("/pages/%{taxon_id}/hierarchy_entries/%{entry_id}/communities")
  match '/pages/:taxon_id/hierarchy_entries/:entry_id/community/collections' => redirect("/pages/%{taxon_id}/hierarchy_entries/%{entry_id}/communities/collections")
  match '/pages/:taxon_id/hierarchy_entries/:entry_id/community/curators' => redirect("/pages/%{taxon_id}/hierarchy_entries/%{entry_id}/communities/curators")
  match '/taxa/content/:taxon_id' => redirect("/pages/%{taxon_id}/details")
  match '/taxa/images/:taxon_id' => redirect("/pages/%{taxon_id}/media")
  match '/taxa/maps/:taxon_id' => redirect("/pages/%{taxon_id}/maps")
  match '/settings' => redirect("/")
  match '/account/show/:user_id' => redirect("/users/%{user_id}")
  match '/users/forgot_password' => redirect("/users/recover_account")
  match '/users/:user_id/reset_password/:recover_account_token' => redirect("/users/recover_account")
  match '/info/xrayvision' => redirect("/collections/14770")
  match '/info/brian-skerry' => redirect("/collections/29285")
  match '/info/naturesbest2011' => redirect("/collections/19338")
  match '/info/naturesbest2012' => redirect("/collections/54659")
  match '/info/naturesbest2013' => redirect("/collections/103870")
  match '/info/naturesbest2015' => redirect("/collections/119460")
  match '/voc/table_of_contents' => redirect("/schema/eol_info_items.xml")
  match '/voc/table_of_contents#:term' => redirect("/schema/eol_info_items.xml%{term}")
  match '/index' => redirect('/')
  match '/home.html' => redirect('/')
  match '/favicon' => redirect('/assets/favicon.ico')
  match '/apple-touch-icon.png' => redirect('/assets/apple-touch-icon.png')
  match '/apple-touch-icon-precomposed.png' => redirect('/assets/apple-touch-icon-precomposed.png')
  match '/forum' => redirect('/forums'), :as => 'forum_redirect'
  match '/schema/terms/:id' => 'schema#terms', :as => 'schema_terms'
  match '/resources/:id' => 'content_partners/resources#show'

  # Taxa nested resources with pages as alias... this is quite large, sorry. Please keep it high in the routes file,
  # since it's 90% of the website.  :)
  resources :pages, :only => [:show], :controller => 'taxa', :as => 'taxa' do
    resource :overview, :only => [:show], :controller => 'taxa/overview'
    resource :tree, :only => [:show], :controller => 'taxa/trees'
    resources :maps, :only => [:index], :controller => 'taxa/maps'
    resources :media, :only => [:show], :controller => 'taxa/media'
    resources :details, :except => [:show], :controller => 'taxa/details'
    resource :worklist, :only => [:show], :controller => 'taxa/worklist'
    resources :data_objects, :only => [:create, :new]
    resource :taxon_concept_reindexing, :as => 'reindexing', :only => [:create],
      :controller => 'taxa/taxon_concept_reindexing'
    resources :data, :only => [:index], :controller => 'taxa/data' do
      collection do
        get 'about'
        get 'glossary'
        get 'ranges'
      end
    end
    resources :hierarchy_entries, :as => 'entries', :only => [:show] do
      member do
        put 'switch'
      end
      resource :overview, :only => [:show], :controller => 'taxa/overview'
      resource :tree, :only => [:show], :controller => 'taxa/trees'
      resources :maps, :only => [:index], :controller => 'taxa/maps'
      resources :media, :only => [:index], :controller => 'taxa/media'
      resources :details, :only => [:index], :controller => 'taxa/details'
      resources :data, :only => [:index], :controller => 'taxa/data' do
        collection do
          get 'about'
          get 'glossary'
          get 'ranges'
        end
      end
      resources :communities, :only => [:index], :controller => 'taxa/communities' do
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
          get 'delete'
        end
        member do
          get 'vet_common_name'
        end
      end
      resource :literature, :only => [:show], :controller => 'taxa/literature' do
        collection do
          get 'bhl'
          get 'literature_links'
        end
      end
      resources :resources, :only => [:index], :controller => 'taxa/resources' do
        collection do
          get 'partner_links'
          get 'identification_resources'
          get 'education'
          get 'nucleotide_sequences'
          get 'biomedical_terms'
          get 'citizen_science'
          get 'news_and_event_links'
          get 'related_organizations'
          get 'multimedia_links'
        end
      end
      resources :updates, :only => [:index], :controller => 'taxa/updates' do
        collection do
          get 'statistics'
        end
      end
    end
    resources :media, :only => [:index], :controller => 'taxa/media'
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
    resource :literature, :only => [:show], :controller => 'taxa/literature' do
      collection do
        get 'bhl'
        get 'literature_links'
      end
    end
    resources :resources, :controller => 'taxa/resources', :only => [:index] do
      collection do
        get 'partner_links'
        get 'identification_resources'
        get 'education'
        get 'nucleotide_sequences'
        get 'biomedical_terms'
        get 'citizen_science'
        get 'news_and_event_links'
        get 'related_organizations'
        get 'multimedia_links'
      end
    end
    resources :communities, :only => [:index], :controller => 'taxa/communities' do
      collection do
        get 'collections'
        get 'curators'
      end
    end
    resources :updates, :only => [:index], :controller => 'taxa/updates' do
      collection do
        get 'statistics'
      end
    end
  end

  # The trait_bank :only list will grow, TODO:
  resources :trait_bank, only: [ :show ]

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
    resource :newsfeed, :only => [:show], :controller => 'communities/newsfeeds'
    resources :collections, :controller => 'communities/collections'
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
      get 'reindex'
    end
    collection do
      get 'get_name'
      get 'get_uri_name'
      get 'cache_inaturalist_projects'
      get 'choose_collect_target'
      get 'choose_editor_target'
      get 'choose_taxa_data'
      post 'collect_item'
      post 'download_taxa_data'
    end
    resource :newsfeed, :only => [:show], :controller => 'collections/newsfeeds'
    resources :editors, :only => [:index], :controller => 'collections/editors'
    resource :inaturalist, :only => [:show], :controller => 'collections/inaturalists'
  end

  resources :collection_jobs, :only => [:create]

  resources :content_partners do
    member do
      post 'new'
    end
    resources :content_partner_contacts, :as => 'contacts', :except => [:index, :show], :controller => 'content_partners/content_partner_contacts' do
      member do
        delete 'delete'
      end
    end
    resources :content_partner_agreements, :as => 'agreements', :except => [:index, :destroy],
      :controller => 'content_partners/content_partner_agreements'
    resource :statistics, :only => [:show], :controller => 'content_partners/statistics'
    resources :resources, :controller => 'content_partners/resources' do
      member do
        get 'force_harvest', :controller => 'content_partners/resources'
        post 'force_harvest', :controller => 'content_partners/resources'
      end
      resources :harvest_events, :only => [:index, :update], :controller => 'content_partners/resources/harvest_events'
      resources :hierarchies, controller: 'content_partners/resources/hierarchies', only: [:edit, :update]  do
        member do
          post 'request_publish', :controller => 'content_partners/resources/hierarchies'
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
      get 'grant_permission'
      get 'revoke_permission'
      get 'revoke_editor'
      get 'pending_notifications'
      get 'reindex'
      get 'scrub'
      get 'unsubscribe_notifications/:key', :action => 'unsubscribe_notifications',
        :as => 'unsubscribe_notifications'
    end
    collection do
      get 'usernames'
      get 'recover_account'
      post 'recover_account'
      get 'verify_open_authentication'
    end
    resource :newsfeed, :only => [:show], :controller => 'users/newsfeeds' do
      collection do
        get 'comments'
      end
    end
    resource :notification, :only => [:edit, :update], :controller => "users/notifications"
    resource :activity, :only => [:show], :controller => 'users/activities'
    resources :collections, :only => [:index], :controller => 'users/collections'
    resources :communities, :only => [:index], :controller => 'users/communities'
    resources :content_partners, :only => [:index], :controller => 'users/content_partners'
    resources :data_downloads, :only => [:index], :controller => 'users/data_downloads' do
      post 'delete'
    end
    resources :open_authentications, :only => [:index, :new, :update, :destroy], :controller => 'users/open_authentications'
  end

  resources :data_objects, :only => [:show, :edit, :update] do
    member do
      put 'curate_associations'
      get 'curation'
      get 'attribution'
      get 'rate'
      get 'crop'
      get 'reindex'
      get 'delete'
    end
    resources :comments
  end

  resources :statistics, :controller => 'eol_statistics', :only => [:index] do
    collection do
      get 'content_partners'
      get 'curators'
      get 'data_objects'
      get 'lifedesks'
      get 'marine'
      get 'page_richness'
      get 'users_data_objects'
      get 'data'
    end
  end

  resource :admin, :only => [:show] do
    collection do
      get :recount_collection_items
    end
    resources :content_pages, :controller => 'admins/content_pages' do
      member do
        post 'move_up'
        post 'move_down'
      end
      resources :children, :only => [:new, :create], :controller => 'admins/content_pages'
      resources :translated_content_pages, :as => :translations, :except => [:show, :index],
        :controller => 'admins/translated_content_pages'
    end
    resources :content_partners, :controller => 'admins/content_partners', :only => [:index] do
      collection do
        get 'statistics'
        post 'statistics'
        get 'notifications'
        post 'notifications'
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
    resources :news_items, :controller => 'admins/news_items' do
      resources :translated_news_items, :as => :translations, :except => [ :show, :index ],
        :controller => 'admins/translated_news_items'
    end
  end

  resources :forum_categories, :controller => 'forums/categories', :only => [ :new, :create, :edit, :update, :destroy ] do
    member do
      post 'move_up'
      post 'move_down'
    end
  end

  # when adding these items when not logged in, the user will get redirected to login
  # then redirected to create via GET. We need to define the abilty to send GET to create
  get '/forums/create' => 'forums#create', :as => 'forums_create'
  get '/forums/:forum_id/topics/create' => 'forums/topics#create', :as => 'forum_topics_create'
  get '/forums/:forum_id/topics/:topic_id/posts/create' => 'forums/posts#create', :as => 'forum_posts_create'
  resources :forums, :only => [ :index, :show, :new, :create, :edit, :update, :destroy ] do
    member do
      post 'move_up'
      post 'move_down'
    end
    resources :topics, :controller => 'forums/topics', :only => [ :show, :create, :destroy ] do
      resources :posts, :controller => 'forums/posts', :only => [ :show, :new, :create, :edit, :update, :destroy ] do
        member do
          get 'reply'
        end
      end
    end
  end

  resources :known_uris do
    collection do
      get 'categories'
      get 'autocomplete_known_uri_search'
      get 'autocomplete_known_uri_units'
      get 'autocomplete_known_uri_metadata'
      get 'autocomplete_known_uri_predicates'
      get 'autocomplete_known_uri_values'
      get 'show_stats'
      post 'import_ontology'
      post 'sort'
    end
    member do
      put 'unhide'
      put 'hide'
      put 'set_as_exemplar_for_same_as'
    end
  end
  resources :known_uri_relationships, :only => [ :create, :destroy ]

  resources :user_added_data, :only => [ :create, :edit, :update, :destroy ]

  resources :taxon_data_exemplars, :only => [ :create ]

  resources :data_point_uris, :only => [ :show ] do
    put 'hide'
    put 'unhide'
    get 'show_metadata'
    resources :comments, :only => [ :index ]
  end

  resource :data_search, :only => [:index], :controller => 'data_search' do
    collection do
      get 'update_attributes'
      get 'index'
      get 'download'
      post 'download'
    end
  end

  resources :data_search_files, only: [:index, :destroy]

  resources :news_items, :only => [:index, :show] do
    resources :translated_news_items, :as => :translations, :except => [:show, :index]
  end

  resource :content_cron_tasks do
    member do
      get 'submit_flickr_comments'
      get 'submit_flickr_curator_actions'
      get 'send_monthly_partner_stats_notification'
    end
  end

  resource :taxon_concept_exemplar_image, only: :create

  resource :data_glossary, :only => :show, :controller => 'data_glossary'

  resource :search, :controller => 'search' do
    collection do
      get 'autocomplete_taxon'
      get 'index'
    end
  end

  # Putting these after the complex resources because they are less common.
  resources :recent_activities, :only => [:index]
  resources :pending_harvests do
    collection do
      post 'sort'
      post 'pause_harvesting'
      post 'resume_harvesting'
    end
  end
  resources :classifications, :only => [:create]
  resources :contacts, :only => [:index, :create, :new]
  resources :collection_items, :only => [:create, :show, :edit, :update]
  resources :comments, :only => [:create, :edit, :update, :destroy]
  # when adding a commenting and not logged in, user will get redirected to login
  # then redirected to create via GET. We need to define the abilty to send GET to create
  get '/comments/create' => 'comments#create'
  resources :sessions, :only => [:new, :create, :destroy]
  resources :wikipedia_imports, :only => [:new, :create] # Curator tool to request import of wikipedia pages
  resources :permissions, :only => [:index, :show]
  resource :feeds do
    member do
      get :partner_curation, :defaults => { :format => 'atom' }
    end
  end

  # Write API /wapi/... The client should set Accept: application/vnd.eol_wapi.v1
  # (for example) to specify a particular version to use. ...Everyone SHOULD do
  # this, though it's not required.
  # NOTE: DRY DOES NOT APPLY TO THESE OLD VERSIONS. In order to keep things in a
  # working state, it is acceptable to copy ENTIRE BLOCKS here! Feel free.
  namespace :wapi, defaults: { format: 'json' } do
    # Be sure to set default: true on the version that you expect people to use.
    scope module: :v1, constraints: ApiConstraints.new(version: 1, default: true) do
      resources :collections
    end
  end

  # Miscellaneous named routes:
  match '/activity_logs/find/:id' => 'feeds#find', :as => 'find_feed'
  match '/contact_us' => 'contacts#new', :as => 'contact_us'
  match '/loggertest' => 'content#loggertest' # This is used for configuring logs and log levels.
  match '/version' => 'content#version'
  match '/boom' => 'content#boom'
  match '/test_timeout/:time' => 'content#test_timeout'

  # Named application routes:
  match '/set_language' => 'application#set_language', :as => 'set_language'
  match '/external_link' => 'application#external_link', :as => 'external_link'
  match '/fetch_external_page_title' => 'application#fetch_external_page_title', :as => 'fetch_external_page_title'

  # Named content routes:
  match '/preview' => 'content#preview', :as => 'preview'
  match '/clear_caches' => 'content#clear_caches', :as => 'clear_caches'
  match '/expire_all' => 'content#expire_all', :as => 'expire_all'
  match '/expire/:id' => 'content#expire_single', :id => /\w+/, :as => 'expire'
  match '/expire_taxon/:id' => 'content#expire_taxon', :id => /\d+/, :as => 'expire_taxon'
  match '/expire_taxa/:id' => 'content#expire_multiple', :id => /\d+/, :as => 'expire_taxa'
  match '/language' => 'content#language', :as => 'language'

  # Search (note there is more search at the end of the file; it is expensive):
  match '/search' => 'search#index', :as => 'search'
  # having this as :q instead of :id was interfering with WillPaginate. See #WEB-4508
  match '/search/:id' => 'search#index'
  match '/found/:id' => 'taxa#show', :as => 'found'

  # Named session routes (see also resources):
  match '/login' => 'sessions#new', :as => 'login'
  match '/logout' => 'sessions#destroy', :as => 'logout'

  # Named curation routes:
  # TODO - PROTIP: If you're doing this, you are doing it wrong. :| Remove.
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

  # TODO - make these resources
  # Named taxon routes:
  # TODO - PROTIP: If you're doing this, you are doing it wrong. :| Remove.
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
  match '/traitbank' => 'content#show', :defaults => {:id => 'traitbank'}, :as => 'traitbank'
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
  resource :administrator, :only => [:index], :controller => 'admin' do
    resources :harvesting_log, :only => [:index], :controller => 'administrator/harvesting_log'
    resources :hierarchy, :only => [:index, :browse, :edit], :controller => 'administrator/hierarchy'
    resources :stats, :only => [:index], :controller => 'administrator/stats' do
      collection do
        get 'SPM_objects_count'
        get 'SPM_partners_count'
        get 'toc_breakdown'
        get 'content_taxonomic'
      end
    end
    resources :user, :controller => 'administrator/user' do
      member do
        get 'hide'
        get 'unhide'
        get 'grant_curator'
        get 'revoke_curator'
        get 'clear_curatorship'
        get 'login_as_user'
        get 'deactivate'
      end
      collection do
        get 'list_newsletter_emails'
      end
    end
    resources :site, :controller => 'administrator/site'
    resources :curator, :controller => 'administrator/curator' do
      collection do
        get 'export'
      end
    end
    resources :comment, :controller => 'administrator/comment' do
      member do
        get 'hide'
      end
    end
    resources :content_upload, :controller => 'administrator/content_upload'
    resources :translation_log, :controller => 'administrator/translation_log'
    resources :user_data_object, :controller => 'administrator/user_data_object'
    resources :error_log, :only => [:index], :controller => 'administrator/error_log'
    resources :table_of_contents, :only => [:index, :create, :edit, :update, :destroy], :controller => 'administrator/table_of_contents'
    resources :search_suggestion, :only => [:index, :create, :new, :edit, :update, :destroy], :controller => 'administrator/search_suggestion'
  end

  resources :eol_configs, only: :update do
    collection do
      post 'change'
    end
  end

  resource :navigation, :controller => 'navigation' do
    member do
      get 'browse_stats'
    end
  end

  resource :wysiwyg, :controller => 'wysiwyg' do
    member do
      post 'upload_image'
    end
  end

  resource :curator_activity_logs, :only => 'index' do
    get 'last_ten_minutes'
  end

  # Old donation routes (for posterity):
  if Rails.configuration.donate_header_url
    get '/donate', to: redirect(Rails.configuration.donate_header_url)
    get '/donation', to: redirect(Rails.configuration.donate_header_url)
    get '/donations', to: redirect(Rails.configuration.donate_header_url)
    get '/donations/new', to: redirect(Rails.configuration.donate_header_url)
  end

  # Named API Routes:
  match 'api' => 'api/docs#index' # Default is actually the documenation
  match 'api/docs' => 'api/docs#index' # Default is actually the documenation
  # not sure why this didn't work in some places - but this is for documentation
  match 'api/docs/:action' => 'api/docs'
  match 'api/docs/:action/:version' => 'api/docs', :version => /\d\.\d/
  # ping is a bit of an exception - it doesn't get versioned and takes no ID
  match 'api/:action' => 'api'
  match 'api/:action/:version' => 'api', :version =>  /\d\.\d/
  # if version is left out we'll set the default to the latest version in the controller
  match 'api/:action/:id' => 'api'
  # looks for version, ID
  match 'api/:action/:version/:id' => 'api', :version =>  /\d\.\d/

  match 'content/random_homepage_images' => 'content#random_homepage_images'
  match 'content/file/:id' => 'content#file'
  match '/maintenance' => 'content#maintenance', :as => 'maintenance'

  # These are expensive and broad and should be kept at the bottom of the file:
  match '/:id' => redirect("/pages/%{id}/overview"), :id => /\d+/
  match '/:q' => 'search#index', :q => /[A-Za-z% ][A-Za-z0-9% ]*/

  # NOTE - I *removed* the default routes.  We shouldn't need them anymore.

  mount Ckeditor::Engine => "/ckeditor" # Required for rich-text editing.

end
