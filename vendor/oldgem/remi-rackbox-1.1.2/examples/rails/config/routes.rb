ActionController::Routing::Routes.draw do |map|

  map.print_method  'print-method',  :controller => 'welcome', :action => 'print_method'
  map.print_session 'print-session', :controller => 'welcome', :action => 'print_session'
  map.redirect      'redirect',      :controller => 'welcome', :action => 'redirect'
  map.some_text     'some_text',     :controller => 'welcome', :action => 'some_text'
  map.some_html     'some_html',     :controller => 'welcome', :action => 'some_html'
  map.relative      'relative',      :controller => 'welcome', :action => 'relative'

  map.root :controller => 'welcome'

end
