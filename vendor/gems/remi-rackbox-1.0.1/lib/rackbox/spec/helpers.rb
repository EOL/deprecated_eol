# Helper methods to include in specs that want to use blackbox testing
#
# This module has the RackBox::SpecHelpers#request method, which is 
# the main method used by RackBox blackbox tests
#
module RackBox::SpecHelpers

  # A port of Merb's request() method, used in tests
  #
  # At the moment, we're using #req instead because #request conflicts 
  # with an existing RSpec-Rails method
  #
  # Usage:
  #   
  #   req '/'
  #   req login_path
  #   req url_for(:controller => 'login')
  #
  #   req '/', :method => :post, :params => { 'chunky' => 'bacon' }
  #
  # TODO support inner hashes, so { :foo => { :chunky => :bacon } } becomes 'foo[chunky]=bacon'
  #
  # TODO take any additional options and pass them along to the environment, so we can say 
  #      req '/', :user_agent => 'some custom user agent'
  #
  def req url, options = {}
    options[:method] ||= (options[:params]) ? :post : :get # if params, default to POST, else default to GET
    options[:params] ||= { }
    @rackbox_request.send options[:method], url, :input => Rack::Utils.build_query(options[:params])
  end

  alias request req unless defined? request

end
