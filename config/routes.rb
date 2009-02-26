ActionController::Routing::Routes.draw do |map|

  # API
  
  # here are some experimental simple RESTful resources for an API
  #
  # the names may very well be changed, I just want to try out some 
  # *simple* controllers before trying to refactor some of our current 
  # controllers.
  #
  # this is a very lay-person type of name which we'll likely change, 
  # this is just for prototyping!
  #
  map.resources :species, :path_prefix => 'v1', :collection => { :search => :get, :random => :get } do |species| 
    species.resources :data_objects
    species.resources :images, :controller => 'data_objects'
    species.resources :videos, :controller => 'data_objects'
  end

  # Web Application

  map.resources :harvest_events, :has_many => [:taxa]
  map.resources :resources, :as => 'content_partner/resources', :has_many => [:harvest_events]
  map.resources :search_logs

  map.resources :comments, :member => { :make_visible => :put, :remove => :put }
	map.resources :random_images
	map.resources :data_objects, :member => { :curate => :put, :curation => :get, :attribution => :get } do |data_objects|
    data_objects.resources :comments
    data_objects.resources :tags,  :collection => { :public => :get, :private => :get, :add_category => :post,
                                                    :autocomplete_for_tag_key => :get }, 
                                   :member => { :autocomplete_for_tag_value => :get }
  end
  map.resources :tags, :collection => { :search => :get }
  map.resources :public_tags, :controller => 'administrator/tag_suggestion'
  
  map.open_id_complete 'authenticate', :controller => "account", :action => "authenticate", :requirements => { :method => :get }

  # The priority is based upon order of creation: first created -> highest priority.
  map.with_options(:controller => 'account') do |account|
    account.login        'login',        :action => 'login'
    account.login_openid 'login/openid', :action => 'login',   :openid => "true"
    account.logout       'logout',       :action => 'logout'
    account.register     'register',     :action => 'signup'
    account.profile      'profile',      :action => 'profile'
  end

  map.resources :taxon
  map.taxon 'taxa/:id',  :controller => 'taxa', :action => 'taxa', :requirements => { :id => /\d+/ }
  map.taxon 'pages/:id', :controller => 'taxa', :action => 'show', :requirements => { :id => /\d+/ }
 
  map.set_language 'set_language', :controller => 'application', :action => 'set_language'
  map.set_flash_enabled 'set_flash_enabled', :controller => 'application', :action => 'set_flash_enabled'

  map.search 'search',:controller => 'taxa', :action => 'search'
  map.home_page 'index',:controller => 'content'  
  map.flash_xml 'flashxml/:id.:format', :controller => 'navigation', :action => 'flash_tree_view'

  map.contact_us 'contact_us', :controller => 'content', :action => 'contact_us'
  map.media_contact 'media_contact', :controller => 'content', :action => 'media_contact'
  
  map.help 'help', :controller => 'content', :action => 'page', :id => 'screencasts'
  map.screencasts 'screencasts', :controller => 'content', :action => 'page', :id => 'screencasts'
  map.faq 'faq', :controller => 'content', :action => 'page', :id => 'faqs'
  map.terms_of_use 'terms_of_use', :controller => 'content', :action => 'page', :id => 'terms_of_use'
  map.donate 'donate',:controller => 'content', :action => 'donate'
  
  map.clear_caches 'clear_caches', :controller=>'content', :action=>'clear_caches'
  map.expire_all 'expire_all', :controller => 'content', :action => 'expire_all'
  map.expire 'expire/:id', :controller=>'content', :action=>'expire_single', :requirements => { :id => /\w+/ }
  map.expire_taxon 'expire_taxon/:id', :controller => 'content', :action => 'expire', :requirements => { :id => /\d+/ }
  map.expire_taxa 'expire_taxa', :controller => 'content', :action => 'expire_multiple'

  map.external_link 'external_link',:controller=>'application', :action=>'external_link'
   
  map.root :controller => 'content'

  map.connect 'search', :controller => 'taxa', :action => 'search'
  
  map.connect 'content_partner/reports', :controller => 'content_partner/reports', :action => 'index' 
  map.connect 'content_partner/reports/:report', :controller => 'content_partner/reports', 
              :action => 'catch_all', :requirements => { :report => /.*/ }

  map.connect 'administrator/reports', :controller => 'administrator/reports', :action => 'index' 
  map.connect 'administrator/reports/:report', :controller => 'administrator/reports', 
              :action => 'catch_all', :requirements => { :report => /.*/ }
              
  map.connect 'administrator/curator', :controller => 'administrator/curator', :action => 'index' 

  map.connect '/taxon_concepts/:taxon_concept_id/comments/', :controller => 'comments', :action => 'index', :conditions => {:method => :get}
  map.connect '/taxon_concepts/:taxon_concept_id/comments/', :controller => 'comments', :action => 'create', :conditions => {:method => :post}
  # Install the default routes as the lowest priority.
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'  
end
