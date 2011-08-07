ActionController::Routing::Routes.draw do |map|

  map.resources :tasks
  map.resources :task_states
  map.resources :task_names

  map.placeholder 'placeholder', :action => 'not_yet_implemented', :controller => 'application'

  map.resources :feed_items
  # Communities nested resources
  # TODO - these member methods want to be :put. Capybara, however, always uses :get, so in the interests of simple tests:
  map.resources :communities,
    :member => { 'join' => :get, 'leave' => :get } do |community|
      community.resource :newsfeed, :only => [:show], :namespace => "communities/"
      community.resources :collection_endorsements, :namespace => "communities/"
      # TODO - these shouldn't be GETs, but I really want them to be links, not forms, sooooo...
      community.resources :members, :member => {'grant_manager' => :get, 'revoke_manager' => :get}
    end

  map.resources :collections, :member => { :choose => :get }
  map.resources :collection_items, :except => [:index, :show, :new, :destroy]

  #used in collections show page, when user clicks on left tabs
  map.connect 'collections/:id/:filter', :controller => 'collections', :action => 'show'

  # Web Application
  map.resources :harvest_events, :has_many => [:taxa]
  map.resources :resources, :as => 'content_partner/resources', :has_many => [:harvest_events]
  map.force_harvest_resource 'content_partner/resources/force_harvest/:id', :method => :post,
      :controller => 'resources', :action => 'force_harvest'

  map.resources :comments, :only => [:create]
  map.resources :random_images
  # TODO - the curate member method is not working when you use the url_for method and its derivatives.  Instead, the default
  # url of "/data_objects/curate/:id" works.  Not sure why.
  map.resources :data_objects, :only => [:show, :edit, :update], :member => { :curate => :put, :curation => :get, :attribution => :get, :rate => :get } do |data_objects|
    data_objects.resources :comments
    data_objects.resources :tags,  :collection => { :public => :get, :private => :get, :add_category => :post,
                                                    :autocomplete_for_tag_key => :get },
                                   :member => { :autocomplete_for_tag_value => :get }
  end
  map.add_association 'data_objects/:id/add_association', :controller => 'data_objects', :action => 'add_association'
  map.save_association 'data_objects/:id/save_association/:hierarchy_entry_id', :controller => 'data_objects', :action => 'save_association'
  map.remove_association 'data_objects/:id/remove_association/:hierarchy_entry_id', :controller => 'data_objects', :action => 'remove_association'

  map.resources :tags, :collection => { :search => :get }

  map.connect 'boom', :controller => 'content', :action => 'error'

  # users
  map.resources :users, :path_names => { :new => :register },
                :member => { :terms_agreement => [ :get, :post ], :pending => :get, :activated => :get,
                             :curation_privileges => [ :get ] },
                :collection => { :forgot_password => :get, :usernames => :get } do |user|
    user.resource :newsfeed, :only => [:show], :controller => "users/newsfeeds"
    user.resource :activity, :only => [:show], :controller => "users/activities"
    user.resources :collections, :only => [:index], :controller => "users/collections"
  end
  map.verify_user '/users/:username/verify/:validation_code', :controller => 'users', :action => 'verify'
  # can't add dynamic segment to a member in rails 2.3 so we have to specify named route:
  map.reset_password_user 'users/:user_id/reset_password/:password_reset_token', :controller => 'users', :action => 'reset_password'

  # sessions
  map.resources :sessions, :only => [:new, :create, :destroy]
  map.login '/login', :controller => 'sessions', :action => 'new'
  map.logout '/logout', :controller => 'sessions', :action => 'destroy'

  # Taxa nested resources with pages as alias
  map.resources :taxa, :as => :pages do |taxa|
    taxa.resources :hierarchy_entries, :as => :entries, :only => [:show], :member => { :switch => [:put] } do |entries|
      entries.resource :overview, :only => [:show], :controller => "taxa/overviews"
      entries.resources :media, :only => [:index], :controller => "taxa/media"
      entries.resources :details, :only => [:index], :controller => "taxa/details"
      entries.resources :names, :only => [:index, :create, :update], :controller => "taxa/names",
                                :collection => { :common_names => :get, :synonyms => :get }
      entries.resource :literature, :only => [:show], :controller => "taxa/literature",
        :member => { :bhl => :get }
      entries.resource :maps, :only => [:show], :controller => "taxa/maps"
    end
    taxa.resource :overview, :only => [:show], :controller => "taxa/overviews"
    taxa.resources :media, :only => [:index], :controller => "taxa/media",
                           :collection => { :set_as_exemplar => [:get, :post] }
    taxa.resources :details, :except => [:show], :controller => "taxa/details"
    taxa.resources :names, :only => [:index, :create, :update], :controller => "taxa/names",
                          :collection => { :common_names => :get, :synonyms => :get }
    taxa.resource :literature, :only => [:show], :controller => "taxa/literature",
      :member => { :bhl => :get }
    taxa.resource :maps, :only => [:show], :controller => "taxa/maps"
    taxa.resources :collections, :only => [:index], :controller => 'collections'
    taxa.resources :communities, :only => [:index], :controller => 'communities'
    taxa.resources :data_objects, :only => [:create, :new], :controller => 'data_objects'
  end
  # used in names tab:
  # when user updates a common name - preferred radio button
  map.connect 'pages/:id/names/common_names/update', :controller => 'taxa', :action => 'update_common_names'
  map.bhl_title 'pages/:id/literature/bhl_title/:title_item_id', :controller => 'taxa/literature', :action => 'bhl_title'
  map.entry_bhl_title 'pages/:id/entries/:hierarchy_entry_id/literature/bhl_title/:title_item_id', :controller => 'taxa/literature', :action => 'bhl_title'


  # Named routes
  map.settings 'settings', :controller => 'taxa', :action => 'settings'
  map.taxon_concept 'pages/:id', :controller => 'taxa', :action => 'show'
  map.page_curators 'pages/:id/curators', :controller => 'taxa', :action => 'curators'

  map.set_language 'set_language', :controller => 'application', :action => 'set_language'

  # some of V1 links - temporarily commented until further notice
  #map.contact_us    'contact_us',    :controller => 'content', :action => 'contact_us'
  #map.media_contact 'media_contact', :controller => 'content', :action => 'media_contact'
  #map.help         'help',         :controller => 'content', :action => 'page', :id => 'screencasts'
  #map.screencasts  'screencasts',  :controller => 'content', :action => 'page', :id => 'screencasts'
  #map.faq          'faq',          :controller => 'content', :action => 'page', :id => 'faqs'
  #map.terms_of_use 'terms_of_use', :controller => 'content', :action => 'page', :id => 'terms_of_use'

  # V2 header links
  map.help        'help',        :controller => 'content', :action => 'page', :id => 'help'
  map.what_is_eol 'what_is_eol', :controller => 'content', :action => 'page', :id => 'what_is_eol'
  map.eol_news    'eol_news',    :controller => 'content', :action => 'page', :id => 'eol_news'
  map.contact_us  'contact_us',  :controller => 'content', :action => 'page', :id => 'contact_us'
  map.donate      'donate',      :controller => 'content', :action => 'donate'
  map.cms_page    'content/page/:id', :controller => 'content', :action => 'page'

  map.clear_caches 'clear_caches',      :controller => 'content', :action => 'clear_caches'
  map.expire_all   'expire_all',        :controller => 'content', :action => 'expire_all'
  map.expire       'expire/:id',        :controller => 'content', :action => 'expire_single',
                                        :requirements => { :id => /\w+/ }
  map.expire_taxon 'expire_taxon/:id',  :controller => 'content', :action => 'expire_taxon',
                                        :requirements => { :id => /\d+/ }
  map.expire_taxa  'expire_taxa',       :controller => 'content', :action => 'expire_multiple'
  map.exemplars    'exemplars.:format', :controller => 'content', :action => 'exemplars'

  map.external_link 'external_link', :controller => 'application', :action => 'external_link'

  map.connect 'search',         :controller => 'search', :action => 'index'
  map.search  'search/:id',     :controller => 'search', :action => 'index'
  map.connect 'search.:format', :controller => 'search', :action => 'index'
  map.found   'found/:id',      :controller => 'search', :action => 'found'

  map.connect 'content_partner/reports', :controller => 'content_partner_account/reports', :action => 'index'
  map.connect 'content_partner/reports/login', :controller => 'content_partner_account', :action => 'login'
  map.connect 'content_partner/reports/:action', :controller => 'content_partner_account/reports'
  map.connect 'content_partner/content/:id', :controller => 'content_partner', :action => 'content', :requirements => { :id => /.*/}
  map.connect 'content_partner/stats/:id', :controller => 'content_partner_account', :action => 'stats', :requirements => { :id => /.*/}

  map.connect 'administrator/reports',         :controller => 'administrator/reports', :action => 'index'
  map.connect 'monthly_stats_email',         :controller => 'administrator/content_partner_report', :action => 'monthly_stats_email'
  map.connect 'administrator/reports/:action', :controller => 'administrator/reports'

  map.request_publish_hierarchy 'content_partner/resources/request_publish/:id', :method => :post,
      :controller => 'content_partner', :action => 'request_publish_hierarchy'

  #map.connect 'administrator/user_data_object',    :controller => 'administrator/user_data_object', :action => 'index'


  # map.connect 'administrator/reports/:report', :controller => 'administrator/reports', :action => 'catch_all',
  #                                              :requirements => { :report => /.*/ }

  map.connect 'administrator/curator', :controller => 'administrator/curator', :action => 'index'

  map.resources :public_tags, :controller => 'administrator/tag_suggestion'
  map.resources :search_logs, :controller => 'administrator/search_logs'

  # TODO = make this resourceful, dammit
  map.connect '/taxon_concepts/:taxon_concept_id/comments/', :controller => 'comments', :action => 'index',
                                                             :conditions => {:method => :get}
  map.connect '/taxon_concepts/:taxon_concept_id/comments/', :controller => 'comments', :action => 'create',
                                                             :conditions => {:method => :post}

  map.admin 'admin',           :controller => 'admin',           :action => 'index'
  map.content_partner 'content_partner', :controller => 'content_partner', :action => 'index'
  map.podcast 'podcast', :controller=>'content', :action=>'page', :id=>'podcast'

  # by default /api goes to the docs
  map.connect 'api', :controller => 'api/docs', :action => 'index'
  # not sure why this didn't work in some places - but this is for documentation
  map.connect 'api/docs/:action', :controller => 'api/docs'
  # ping is a bit of an exception - it doesn't get versioned and takes no ID
  map.connect 'api/:action', :controller => 'api', :version => '0.4'
  map.connect 'api/:action.:format', :controller => 'api', :version => '0.4'
  map.connect 'api/:action/:version', :controller => 'api', :version => /[0-1]\.[0-9]/
  map.connect 'api/:action/:version.:format', :controller => 'api', :version => /[0-1]\.[0-9]/
  # if version is left out we'll default to the older 0.4
  map.connect 'api/:action/:id', :controller => 'api', :version => '0.4'
  map.connect 'api/:action/:id.:format', :controller => 'api', :version => '0.4'
  # looks for version, ID and format
  map.connect 'api/:action/:version/:id', :controller => 'api', :version => /[0-1]\.[0-9]/
  map.connect 'api/:action/:version/:id.:format', :controller => 'api', :version => /[0-1]\.[0-9]/

  map.connect 'curators', :controller => 'curators'

  ## Mobile app namespace routes
  map.mobile 'mobile', :controller => 'mobile/contents'
  map.namespace :mobile do |mobile|
    mobile.resources :contents, :collection => {:enable => [:post, :get], :disable => [:post, :get]}
    mobile.resources :taxa, :member => {:details => :get, :media => :get}
    mobile.search 'search/:id', :controller => 'search', :action => 'index'
  end

  ##### ALL ROUTES BELOW SHOULD PROBABLY ALWAYS BE AT THE BOTTOM SO THEY ARE RUN LAST ####
  # this represents a URL with just a random namestring -- send to search page (e.g. www.eol.org/animalia)
  # ...with the exception of "index", which historically pointed to home:
  map.connect '/index', :controller => 'content', :action => 'index'
  map.connect ':id', :id => /\d+/,  :controller => 'taxa', :action => 'show' # only a number passed in to the root of the web, then assume a specific taxon concept ID
  map.connect ':id', :id => /[A-Za-z0-9% ]+/,  :controller => 'taxa', :action => 'search'  # if text, then go to the search page

  # Install the default routes as the lowest priority.
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'

  map.root :controller => 'content', :action => 'index'

end
