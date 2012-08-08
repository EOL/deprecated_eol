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

  resources :tasks, :task_states, :task_names, :feed_items, :random_images
  resources :recent_activities, :only => [:index]
  resources :classifications, :only => [:create]
  resources :contacts, :only => [:index, :create, :new]
  resources :collection_items, :only => [:create, :edit, :update]
  resources :comments, :only => [:create, :edit, :update, :destroy]
  resources :sessions, :only => [:new, :create, :destroy]
  resources :wikipedia_imports, :only => [:new, :create] # Curator tool to request import of wikipedia pages

##   map.set_article_as_exemplar 'pages/:taxon_id/details/:data_object_id/set_article_as_exemplar', :controller => 'taxa/details', :action => 'set_article_as_exemplar'
##   map.bhl_title 'pages/:id/literature/bhl_title/:title_item_id', :controller => 'taxa/literature', :action => 'bhl_title'
##   map.entry_bhl_title 'pages/:id/entries/:hierarchy_entry_id/literature/bhl_title/:title_item_id', :controller => 'taxa/literature', :action => 'bhl_title'
##   map.taxon_worklist_data_object 'pages/:id/worklist/data_objects/:data_object_id', :controller => 'taxa/worklist', :action => 'data_objects'
#
#  # Communities nested resources
#  # TODO - these member methods want to be :put. Capybara always uses :get, so in the interests of simple tests:
##   map.resources :communities, :except => [:index],
##     :collection => { :choose => :get, :make_editors => :put },
##     :member => { :join => :get, :leave => :get, :delete => :get,
##                  :make_editor => :put, :revoke_editor => :get } do |community|
##       community.resource :newsfeed, :only => [:show], :namespace => "communities/"
##       community.resources :collections, :namespace => "communities/"
##       # TODO - these shouldn't be GETs, but I really want them to be links, not forms, sooooo...
##       community.resources :members, :member => {'grant_manager' => :get, 'revoke_manager' => :get}
##     end
## 
##   map.resources :collections, :member => { :choose => :get },
##                               :collection => { :choose_collect_target => :get,
##                                                :choose_editor_target => :get,
##                                                :collect_item => :post } do |collection|
##       collection.resource :newsfeed, :only => [:show], :namespace => "collections/"
##       collection.resource :editors, :only => [:show], :namespace => "collections/"
##       collection.resource :inaturalist, :only => [:show], :namespace => "collections/"
##   end
##
##   # Not nesting collection_items under collections: creation is complex, plus edit only used for non-JS users
##   #used in collections show page, when user clicks on left tabs
##   map.filtered_collection 'collections/:id/:filter', :controller => 'collections', :action => 'show'
## 
##   # content partners and their nested resources
##   map.resources :content_partners do |content_partner|
##     content_partner.resources :content_partner_contacts, :as => :contacts,
##                                                          :except => [:index, :show],
##                                                          :namespace => "content_partners/"
##     content_partner.resources :content_partner_agreements, :as => :agreements,
##                                                          :except => [:index, :destroy],
##                                                          :namespace => "content_partners/"
##     content_partner.resources :resources, :member => {:force_harvest => [:get, :post]},
##                                           :namespace => "content_partners/" do |resource|
##       resource.resources :harvest_events, :only => [:index, :update], :namespace => "content_partners/resources/"
##       resource.resources :hierarchies, :only => [:edit, :update], :member => { :request_publish => :post },
##                                        :namespace => "content_partners/resources/"
##     end
##     content_partner.resource :statistics, :only => [:show], :namespace => "content_partners/"
##   end
## 
## 
##   # TODO - the curate member method is not working when you use the url_for method and its derivatives.  Instead, the default
##   # url of "/data_objects/curate/:id" works.  Not sure why.
##   map.resources :data_objects, :only => [:show, :edit, :update], :member => { :curate => :put, :curation => :get, :attribution => :get, :rate => :get } do |data_objects|
##     data_objects.resources :comments
##     data_objects.resources :tags,  :collection => { :public => :get, :private => :get, :add_category => :post,
##                                                     :autocomplete_for_tag_key => :get },
##                                    :member => { :autocomplete_for_tag_value => :get }
##   end
##   map.data_object_ignore 'data_objects/:id/ignore', :controller => 'data_objects', :action => 'ignore'
##   map.add_association 'data_objects/:id/add_association', :controller => 'data_objects', :action => 'add_association'
##   map.save_association 'data_objects/:id/save_association/:hierarchy_entry_id', :controller => 'data_objects', :action => 'save_association'
##   map.remove_association 'data_objects/:id/remove_association/:hierarchy_entry_id', :controller => 'data_objects', :action => 'remove_association'
## 
##   map.resources :tags, :collection => { :search => :get }
## 
##   map.connect 'loggertest', :controller => 'content', :action => 'loggertest' # This is used for configuring logs and log levels.
##   map.connect 'boom', :controller => 'content', :action => 'boom'
## 
##   # users
##   map.resources :users, :path_names => { :new => :register },
##                 :member => { :terms_agreement => [ :get, :post ], :pending => :get, :activated => :get,
##                              :curation_privileges => :get, :make_editor => :put, :revoke_editor => :get,
##                              :pending_notifications => :get },
##                 :collection => { :usernames => :get, :recover_account => :get,
##                                  :verify_open_authentication => :get } do |user|
##     user.resource :newsfeed, :only => [:show], :collection => { :comments => [:get] },
##                              :controller => "users/newsfeeds"
##     user.resource :notification, :only => [:edit, :update], :controller => "users/notifications"
##     user.resource :activity, :only => [:show], :controller => "users/activities"
##     user.resources :collections, :only => [:index], :controller => "users/collections"
##     user.resources :communities, :only => [:index], :controller => "users/communities"
##     user.resources :content_partners, :only => [:index], :namespace => "users/"
##     user.resources :open_authentications, :only => [:index, :new, :update, :destroy], :namespace => "users/" # OAuth for existing users
##   end
##   # can't add dynamic segment to a member in rails 2.3 so we have to specify named routes for the following:
##   map.verify_user '/users/:user_id/verify/:validation_code', :controller => 'users', :action => 'verify'
##   map.temporary_login_user 'users/:user_id/temporary_login/:recover_account_token',
##                            :controller => 'users', :action => 'temporary_login'
## 
##   # Taxa nested resources with pages as alias
##   map.resources :taxa, :only => [:show], :as => :pages do |taxa|
##     taxa.resources :hierarchy_entries, :as => :entries, :only => [:show], :member => { :switch => [:put] } do |entries|
##       entries.resource :tree, :only => [:show], :controller => "taxa/trees"
##       entries.resource :overview, :only => [:show], :controller => "taxa/overviews"
##       entries.resources :media, :only => [:index], :controller => "taxa/media"
##       entries.resources :details, :only => [:index], :controller => "taxa/details"
##       entries.resources :communities, :as => :community, :only => [:index], :controller => "taxa/communities",
##         :collection => { :collections => :get, :curators => :get }
##       entries.resources :names, :only => [:index, :create, :update], :controller => "taxa/names",
##                                 :collection => { :common_names => :get, :related_names => :get, :synonyms => :get },
##                                 :member => { :vet_common_name => :get }
##       entries.resource :literature, :only => [:show], :controller => "taxa/literature",
##         :member => { :bhl => :get }
##       entries.resource :resources, :only => [:show], :controller => "taxa/resources",
##         :member => { :identification_resources => :get, :education => :get , :nucleotide_sequences => :get, :biomedical_terms => :get,
##           :citizen_science => :get }
##       entries.resource :maps, :only => [:show], :controller => "taxa/maps"
##       entries.resource :updates, :only => [:show], :controller => "taxa/updates",
##         :member => { :statistics => :get }
##     end
##     taxa.resource :tree, :only => [:show], :controller => "taxa/trees"
##     taxa.resource :overview, :only => [:show], :controller => "taxa/overviews"
##     taxa.resources :media, :only => [:index], :controller => "taxa/media",
##                            :collection => { :set_as_exemplar => [:get, :post] }
##     taxa.resources :details, :except => [:show], :controller => "taxa/details"
##     taxa.resources :names, :only => [:index, :create, :update], :controller => "taxa/names",
##                           :collection => { :common_names => :get, :related_names => :get,
##                                            :synonyms => :get, :delete => :get },
##                           :member => { :vet_common_name => :get }
##     taxa.resource :literature, :only => [:show], :controller => "taxa/literature",
##       :member => { :bhl => :get }
##     taxa.resource :resources, :only => [:show], :controller => "taxa/resources",
##       :member => { :identification_resources => :get, :education => :get , :nucleotide_sequences => :get , :biomedical_terms => :get,
##         :citizen_science => :get }
##     taxa.resources :communities, :as => :community, :only => [:index], :controller => "taxa/communities",
##        :collection => { :collections => :get, :curators => :get }
##     taxa.resource :maps, :only => [:show], :controller => "taxa/maps"
##     taxa.resource :updates, :only => [:show], :controller => "taxa/updates",
##       :member => { :statistics => :get }
##     taxa.resource :worklist, :only => [:show], :controller => "taxa/worklist"
##     taxa.resources :data_objects, :only => [:create, :new], :controller => 'data_objects'
##   end
#
##   map.resources :eol_statistics, :as => 'statistics', :only => [:index],
##                                  :collection => { :content_partners => [:get],
##                                                   :curators => [:get],
##                                                   :data_objects => [:get],
##                                                   :lifedesks => [:get],
##                                                   :marine => [:get],
##                                                   :page_richness => [:get],
##                                                   :users_data_objects => [:get] }
## 
##   # New V2 /admins namespace with singular resource admin
##   map.resource :admin, :only => [:show] do |admin|
##     admin.resources :content_pages, :member => {:move_up => :post, :move_down => :post}, :namespace => 'admins/' do |content_page|
##       content_page.resources :children, :only => [:new, :create], :controller => 'content_pages'
##       content_page.resources :translated_content_pages, :as => :translations, :except => [:show, :index], :controller => 'translated_content_pages'
##     end
##     admin.resources :content_partners, :collection => {:notifications => [:get, :post], :statistics => [:get, :post]},
##                                        :only => [:index], :namespace => 'admins/'
##     admin.resources :eol_statistics, :as => 'statistics', :only => [:index],
##                                      :collection => {:content_partners => [:get],
##                                                  :data_objects => [:get],
##                                                  :marine => [:get],
##                                                  :curators => [:get],
##                                                  :page_richness => [:get],
##                                                  :users_data_objects => [:get],
##                                                  :lifedesks => [:get]},
##                                      :namespace => 'admins/'
##   end
## 
##   # Old V1 /admin and /administrator namespaces (controllers)
##   map.administrator 'administrator',           :controller => 'admin',           :action => 'index'
##   map.connect 'administrator/reports',         :controller => 'administrator/reports', :action => 'index'
##   map.connect 'administrator/reports/:action', :controller => 'administrator/reports'
##   #map.connect 'administrator/user_data_object',    :controller => 'administrator/user_data_object', :action => 'index'
##   # map.connect 'administrator/reports/:report', :controller => 'administrator/reports', :action => 'catch_all',
##   #                                              :requirements => { :report => /.*/ }
##   map.connect 'administrator/curator', :controller => 'administrator/curator', :action => 'index'
##   map.connect 'administrator/translation_log', :controller => 'administrator/translation_log', :action => 'index'
##   map.resources :search_logs, :controller => 'administrator/search_logs'
## 
##   # TODO = make this resourceful, dammit - are these now obsolete?
##   map.connect '/taxon_concepts/:taxon_concept_id/comments/', :controller => 'comments', :action => 'index',
##                                                              :conditions => {:method => :get}
##   map.connect '/taxon_concepts/:taxon_concept_id/comments/', :controller => 'comments', :action => 'create',
##                                                              :conditions => {:method => :post}
## 
##   # by default /api goes to the docs
##   map.connect 'api', :controller => 'api/docs', :action => 'index'
##   # not sure why this didn't work in some places - but this is for documentation
##   map.connect 'api/docs/:action', :controller => 'api/docs'
##   # ping is a bit of an exception - it doesn't get versioned and takes no ID
##   map.connect 'api/:action', :controller => 'api'
##   map.connect 'api/:action.:format', :controller => 'api'
##   map.connect 'api/:action/:version', :controller => 'api', :version => /[0-1]\.[0-9]/
##   map.connect 'api/:action/:version.:format', :controller => 'api', :version => /[0-1]\.[0-9]/
##   # if version is left out we'll set the default to the latest version in the controller
##   map.connect 'api/:action/:id', :controller => 'api'
##   map.connect 'api/:action/:id.:format', :controller => 'api'
##   # looks for version, ID and format
##   map.connect 'api/:action/:version/:id', :controller => 'api', :version => /[0-1]\.[0-9]/
##   map.connect 'api/:action/:version/:id.:format', :controller => 'api', :version => /[0-1]\.[0-9]/
## 
##   ## Content pages including CMS and other miscellaneous pages
##   map.with_options :controller => 'content', :action => 'show', :conditions => { :method => :get } do |content_page|
##     content_page.help         '/help',             :id => 'help'
##     content_page.about        '/about',            :id => 'about'
##     content_page.news         '/news',             :id => 'news'
##     content_page.discover     '/discover',         :id => 'explore_biodiversity'
##     content_page.contact      '/contact',          :id => 'contact'
##     content_page.terms_of_use '/terms_of_use',     :id => 'terms_of_use'
##     content_page.citing       '/citing',           :id => 'citing'
##     content_page.privacy      '/privacy',          :id => 'privacy'
##     content_page.curators     '/curators/*ignore', :id => 'curators'
##     content_page.cms_page     '/info/:id'
##     content_page.cms_crumbs   '/info/*crumbs'
##   end


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
