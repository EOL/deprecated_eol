ActionController::Routing::Routes.draw do |map|

  map.find_feed '/activity_logs/find/:id', :controller => 'feeds', :action => 'find'
  map.preview '/preview', :controller => 'content', :action => 'preview'

  map.resources :tasks
  map.resources :task_states
  map.resources :task_names

  map.placeholder 'placeholder', :action => 'not_yet_implemented', :controller => 'application'

  map.resources :feed_items
  # Communities nested resources
  # TODO - these member methods want to be :put. Capybara, however, always uses :get, so in the interests of simple tests:
  map.resources :communities, :except => [:index],
    :collection => { :choose => :get, :make_editors => :put },
    :member => { :join => :get, :leave => :get, :delete => :get,
                 :make_editor => :put, :revoke_editor => :get } do |community|
      community.resource :newsfeed, :only => [:show], :namespace => "communities/"
      community.resources :collections, :namespace => "communities/"
      # TODO - these shouldn't be GETs, but I really want them to be links, not forms, sooooo...
      community.resources :members, :member => {'grant_manager' => :get, 'revoke_manager' => :get}
    end

  map.resources :collections, :member => { :choose => :get },
                              :collection => { :choose_collect_target => :get,
                                               :choose_editor_target => :get,
                                               :collect_item => :post }
  map.resources :collection_items, :except => [:index, :show, :new, :destroy]
  #used in collections show page, when user clicks on left tabs
  map.filtered_collection 'collections/:id/:filter', :controller => 'collections', :action => 'show'

  # content partners and their nested resources
  map.resources :content_partners do |content_partner|
    content_partner.resources :content_partner_contacts, :as => :contacts,
                                                         :except => [:index, :show],
                                                         :namespace => "content_partners/"
    content_partner.resources :content_partner_agreements, :as => :agreements,
                                                         :except => [:index, :destroy],
                                                         :namespace => "content_partners/"
    content_partner.resources :resources, :member => {:force_harvest => [:get, :post]},
                                          :namespace => "content_partners/" do |resource|
      resource.resources :harvest_events, :only => [:index, :update], :namespace => "content_partners/resources/"
      resource.resources :hierarchies, :only => [:edit, :update], :member => { :request_publish => :post },
                                       :namespace => "content_partners/resources/"
    end
    content_partner.resource :statistics, :only => [:show], :namespace => "content_partners/"
  end

  map.resources :comments, :only => [ :create, :edit, :update, :destroy ]
  map.connect '/comments/:id', :controller => 'comments', :action => 'destroy', :id => /\d+/

  map.resources :random_images
  # TODO - the curate member method is not working when you use the url_for method and its derivatives.  Instead, the default
  # url of "/data_objects/curate/:id" works.  Not sure why.
  map.resources :data_objects, :only => [:show, :edit, :update], :member => { :curate => :put, :curation => :get, :attribution => :get, :rate => :get } do |data_objects|
    data_objects.resources :comments
    data_objects.resources :tags,  :collection => { :public => :get, :private => :get, :add_category => :post,
                                                    :autocomplete_for_tag_key => :get },
                                   :member => { :autocomplete_for_tag_value => :get }
  end
  map.data_object_ignore 'data_objects/:id/ignore', :controller => 'data_objects', :action => 'ignore'
  map.add_association 'data_objects/:id/add_association', :controller => 'data_objects', :action => 'add_association'
  map.save_association 'data_objects/:id/save_association/:hierarchy_entry_id', :controller => 'data_objects', :action => 'save_association'
  map.remove_association 'data_objects/:id/remove_association/:hierarchy_entry_id', :controller => 'data_objects', :action => 'remove_association'

  map.resources :tags, :collection => { :search => :get }

  map.connect 'loggertest', :controller => 'content', :action => 'loggertest' # This is used for configuring logs and log levels.
  map.connect 'boom', :controller => 'content', :action => 'boom'

  # users
  map.resources :users, :path_names => { :new => :register },
                :member => { :terms_agreement => [ :get, :post ], :pending => :get, :activated => :get,
                             :curation_privileges => [ :get ], :make_editor => :put, :revoke_editor => :get },
                :collection => { :forgot_password => :get, :usernames => :get } do |user|
    user.resource :newsfeed, :only => [:show], :controller => "users/newsfeeds"
    user.resource :activity, :only => [:show], :controller => "users/activities"
    user.resources :collections, :only => [:index], :controller => "users/collections"
    user.resources :communities, :only => [:index], :controller => "users/communities"
    user.resources :content_partners, :only => [:index], :namespace => "users/"
  end
  map.verify_user '/users/:user_id/verify/:validation_code', :controller => 'users', :action => 'verify'
  # can't add dynamic segment to a member in rails 2.3 so we have to specify named route:
  map.reset_password_user 'users/:user_id/reset_password/:password_reset_token', :controller => 'users', :action => 'reset_password'

  # sessions
  map.resources :sessions, :only => [:new, :create, :destroy]
  map.login '/login', :controller => 'sessions', :action => 'new'
  map.logout '/logout', :controller => 'sessions', :action => 'destroy'

  # Taxa nested resources with pages as alias
  map.resources :taxa, :only => [:show], :as => :pages do |taxa|
    taxa.resources :hierarchy_entries, :as => :entries, :only => [:show], :member => { :switch => [:put] } do |entries|
      entries.resource :tree, :only => [:show], :controller => "taxa/trees"
      entries.resource :overview, :only => [:show], :controller => "taxa/overviews"
      entries.resources :media, :only => [:index], :controller => "taxa/media"
      entries.resources :details, :only => [:index], :controller => "taxa/details"
      entries.resources :communities, :as => :community, :only => [:index], :controller => "taxa/communities",
        :collection => { :collections => :get, :curators => :get }
      entries.resources :names, :only => [:index, :create, :update], :controller => "taxa/names",
                                :collection => { :common_names => :get, :synonyms => :get },
                                :member => { :vet_common_name => :get }
      entries.resource :literature, :only => [:show], :controller => "taxa/literature",
        :member => { :bhl => :get }
      entries.resource :resources, :only => [:show], :controller => "taxa/resources",
        :member => { :identification_resources => :get, :education => :get , :nucleotide_sequences => :get, :biomedical_terms => :get }
      entries.resource :maps, :only => [:show], :controller => "taxa/maps"
      entries.resource :updates, :only => [:show], :controller => "taxa/updates",
        :member => { :statistics => :get }
    end
    taxa.resource :overview, :only => [:show], :controller => "taxa/overviews"
    taxa.resources :media, :only => [:index], :controller => "taxa/media",
                           :collection => { :set_as_exemplar => [:get, :post] }
    taxa.resources :details, :except => [:show], :controller => "taxa/details"
    taxa.resources :names, :only => [:index, :create, :update], :controller => "taxa/names",
                          :collection => { :common_names => :get, :synonyms => :get },
                          :member => { :vet_common_name => :get }
    taxa.resource :literature, :only => [:show], :controller => "taxa/literature",
      :member => { :bhl => :get }
    taxa.resource :resources, :only => [:show], :controller => "taxa/resources",
      :member => { :identification_resources => :get, :education => :get , :nucleotide_sequences => :get , :biomedical_terms => :get }
    taxa.resources :communities, :as => :community, :only => [:index], :controller => "taxa/communities",
       :collection => { :collections => :get, :curators => :get }
    taxa.resource :maps, :only => [:show], :controller => "taxa/maps"
    taxa.resource :updates, :only => [:show], :controller => "taxa/updates",
      :member => { :statistics => :get }
    taxa.resource :worklist, :only => [:show], :controller => "taxa/worklist"
    taxa.resources :data_objects, :only => [:create, :new], :controller => 'data_objects'
  end
  # used in names tab:
  # when user updates a common name - preferred radio button
  map.connect 'pages/:id/names/common_names/update', :controller => 'taxa', :action => 'update_common_names'
  map.bhl_title 'pages/:id/literature/bhl_title/:title_item_id', :controller => 'taxa/literature', :action => 'bhl_title'
  map.entry_bhl_title 'pages/:id/entries/:hierarchy_entry_id/literature/bhl_title/:title_item_id', :controller => 'taxa/literature', :action => 'bhl_title'
  map.taxon_worklist_data_object 'pages/:id/worklist/data_objects/:data_object_id', :controller => 'taxa/worklist', :action => 'data_objects'


  # Named routes (are some of these obsolete?)
  map.taxon_concept 'pages/:id', :controller => 'taxa', :action => 'show'
  map.set_language 'set_language', :controller => 'application', :action => 'set_language'

  map.clear_caches 'clear_caches',      :controller => 'content', :action => 'clear_caches'
  map.expire_all   'expire_all',        :controller => 'content', :action => 'expire_all'
  map.expire       'expire/:id',        :controller => 'content', :action => 'expire_single',
                                        :requirements => { :id => /\w+/ }
  map.expire_taxon 'expire_taxon/:id',  :controller => 'content', :action => 'expire_taxon',
                                        :requirements => { :id => /\d+/ }
  map.expire_taxa  'expire_taxa',       :controller => 'content', :action => 'expire_multiple'

  map.external_link 'external_link', :controller => 'application', :action => 'external_link'

  map.search_q  'search',         :controller => 'search', :action => 'index'
  map.search    'search/:id',     :controller => 'search', :action => 'index'
  map.connect   'search.:format', :controller => 'search', :action => 'index'
  map.found     'found/:id',      :controller => 'taxa', :action => 'show'

  # New V2 /admins namespace with singular resource admin
  map.resource :admin, :only => [:show] do |admin|
    admin.resources :content_pages, :member => {:move_up => :post, :move_down => :post}, :namespace => 'admins/' do |content_page|
      content_page.resources :children, :only => [:new, :create], :controller => 'content_pages'
      content_page.resources :translated_content_pages, :as => :translations, :except => [:show, :index], :controller => 'translated_content_pages'
    end
    admin.resources :content_partners, :collection => {:notifications => [:get, :post], :statistics => [:get, :post]},
                                       :only => [:index], :namespace => 'admins/' do |content_partner|

    end
  end

  # Old V1 /admin and /administrator namespaces (controllers)
  map.administrator 'administrator',           :controller => 'admin',           :action => 'index'
  map.connect 'administrator/reports',         :controller => 'administrator/reports', :action => 'index'
  map.connect 'administrator/reports/:action', :controller => 'administrator/reports'
  #map.connect 'administrator/user_data_object',    :controller => 'administrator/user_data_object', :action => 'index'
  # map.connect 'administrator/reports/:report', :controller => 'administrator/reports', :action => 'catch_all',
  #                                              :requirements => { :report => /.*/ }
  map.connect 'administrator/curator', :controller => 'administrator/curator', :action => 'index'
  map.resources :search_logs, :controller => 'administrator/search_logs'

  # TODO = make this resourceful, dammit - are these now obsolete?
  map.connect '/taxon_concepts/:taxon_concept_id/comments/', :controller => 'comments', :action => 'index',
                                                             :conditions => {:method => :get}
  map.connect '/taxon_concepts/:taxon_concept_id/comments/', :controller => 'comments', :action => 'create',
                                                             :conditions => {:method => :post}

  # by default /api goes to the docs
  map.connect 'api', :controller => 'api/docs', :action => 'index'
  # not sure why this didn't work in some places - but this is for documentation
  map.connect 'api/docs/:action', :controller => 'api/docs'
  # ping is a bit of an exception - it doesn't get versioned and takes no ID
  map.connect 'api/:action', :controller => 'api'
  map.connect 'api/:action.:format', :controller => 'api'
  map.connect 'api/:action/:version', :controller => 'api', :version => /[0-1]\.[0-9]/
  map.connect 'api/:action/:version.:format', :controller => 'api', :version => /[0-1]\.[0-9]/
  # if version is left out we'll set the default to the latest version in the controller
  map.connect 'api/:action/:id', :controller => 'api'
  map.connect 'api/:action/:id.:format', :controller => 'api'
  # looks for version, ID and format
  map.connect 'api/:action/:version/:id', :controller => 'api', :version => /[0-1]\.[0-9]/
  map.connect 'api/:action/:version/:id.:format', :controller => 'api', :version => /[0-1]\.[0-9]/

  ## Mobile app namespace routes
  map.mobile 'mobile', :controller => 'mobile/contents'
  map.namespace :mobile do |mobile|
    mobile.resources :contents, :collection => {:enable => [:post, :get], :disable => [:post, :get]}
    mobile.resources :taxa, :only => [:show], :as => :pages do |taxa|
      taxa.resources :details, :only => [:index], :controller => "taxa/details"
      taxa.resources :media, :only => [:index], :controller => "taxa/media"
    end
  #  mobile.search 'search/:id', :controller => 'search', :action => 'index' # this looks for mobile/search controller but I'm using the main search controller instead
  end
  map.mobile_search 'mobile/search/:id', :controller => 'search', :action => 'index'

  ## Content pages including CMS and other miscellaneous pages
  map.with_options :controller => 'content', :action => 'show', :conditions => { :method => :get } do |content_page|
    content_page.help         '/help',             :id => 'help'
    content_page.about        '/about',            :id => 'about'
    content_page.news         '/news',             :id => 'news'
    content_page.discover     '/discover',         :id => 'explore_biodiversity'
    content_page.contact      '/contact',          :id => 'contact'
    content_page.terms_of_use '/terms_of_use',     :id => 'terms_of_use'
    content_page.citing       '/citing',           :id => 'citing'
    content_page.privacy      '/privacy',          :id => 'privacy'
    content_page.curators     '/curators/*ignore', :id => 'curators'
    content_page.cms_page     '/info/:id'
    content_page.cms_crumbs   '/info/*crumbs'
  end
  map.donate '/donate', :controller => 'content', :action => 'donate'
  map.language '/language', :controller => 'content', :action => 'language'

  ## Permanent redirects.
  map.with_options :controller => 'redirects', :action => 'show', :conditions => { :method => :get } do |redirect|
    redirect.connect '/podcast', :url => 'http://education.eol.org/podcast'
    redirect.connect '/pages/:taxon_id/curators'
    # TODO - remove /content/* named routes once search engines have reindexed the site and legacy URLs are not in use.
    redirect.connect '/content/exemplars', :conditional_redirect_id  => 'exemplars'
    redirect.connect '/content/news/*ignore', :cms_page_id => 'news'
    redirect.connect '/content/page/2012eolfellowsapplication', :cms_page_id => '2012_eol_fellows_application'
    redirect.connect '/content/page/2012fellowsonlineapp',  :cms_page_id => '2012_fellows_online_app'
    redirect.connect '/content/page/curator_central', :cms_page_id => 'curators'
    redirect.connect '/content/page/:cms_page_id'
    redirect.connect '/settings'
    redirect.connect '/account/show/:user_id'
  end

  ## Curator tool to request import of wikipedia pages
  map.resources :wikipedia_queues, :as => :wikipedia_imports, :only => [:new, :create]

  ##### ALL ROUTES BELOW SHOULD PROBABLY ALWAYS BE AT THE BOTTOM SO THEY ARE RUN LAST ####
  # this represents a URL with just a random namestring -- send to search page (e.g. www.eol.org/animalia)
  # ...with the exception of "index", which historically pointed to home:
  map.connect '/index', :controller => 'content', :action => 'index'
  map.connect ':id', :id => /\d+/,  :controller => 'taxa', :action => 'show' # only a number passed in to the root of the web, then assume a specific taxon concept ID
  map.connect ':id', :id => /[A-Za-z0-9% ]+/,  :controller => 'search'  # if text, then go to the search page

  # Install the default routes as the lowest priority.
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'

  map.root :controller => 'content', :action => 'index'

end
