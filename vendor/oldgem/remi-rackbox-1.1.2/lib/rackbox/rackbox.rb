
# To add blackbox testing to a Rails app,
# in your spec_helper.rb
#
#   require 'rackbox'
#
#   Spec::Runner.configure do |config|
#     config.use_blackbox = true
#   end
#
class RackBox

  # i am an rdoc comment on RackBox's eigenclass
  class << self

    # to turn on some verbosity / logging, set:
    #   RackBox.verbose = true
    attr_accessor :verbose

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
    #   req '/', :data => "some XML data to POST"
    #
    # TODO take any additional options and pass them along to the environment, so we can say 
    #      req '/', :user_agent => 'some custom user agent'
    #
    def req app_or_request, url = nil, options = {}
      puts "RackBox#request url:#{ url.inspect }, options:#{ options.inspect }" if RackBox.verbose

      # handle RackBox.request '/foo'
      if app_or_request.is_a?(String) && ( url.nil? || url.is_a?(Hash) )
        options        = url || {}
        url            = app_or_request
        app_or_request = RackBox.app
      end

      # need to find the request or app
      mock_request = nil
      if app_or_request.is_a? Rack::MockRequest
        mock_request = app_or_request
      elsif app_or_request.nil?
        if RackBox.app.nil?
          raise "Not sure howto to execute a request against app or request: #{ app_or_request.inspect }"
        else
          mock_request = Rack::MockRequest.new(RackBox.app) # default to RackBox.app if nil
        end
      elsif app_or_request.respond_to? :call
        mock_request = Rack::MockRequest.new(app_or_request)
      else
        raise "Not sure howto to execute a request against app or request: #{ app_or_request.inspect }"
      end

      options[:method] ||= ( options[:params] || options[:data] ) ? :post : :get # if params, default to POST, else default to GET
      options[:params] ||= { }

      if options[:data]
        # input should be the data we're likely POSTing ... this overrides any params
        input = options[:data]
      else
        # input should be params, if any
        input = RackBox.build_query options[:params]
      end

      headers = options.dup
      headers.delete :data   if headers[:data]
      headers.delete :params if headers[:params]
      headers.delete :method if headers[:method]
      
      # merge input
      headers[:input] = input
      
      puts "  requesting #{ options[:method].to_s.upcase } #{ url.inspect } #{ headers.inspect }" if RackBox.verbose
      mock_request.send options[:method], url, headers
    end

    alias request req unless defined? request

    # the Rack appliction to do 'Black Box' testing against
    #
    # To set, in your spec_helper.rb or someplace:
    #   RackBox.app = Rack::Adapter::Rails.new :root => '/root/directory/of/rails/app', :environment => 'test'
    #
    # If not explicitly set, uses RAILS_ROOT (if defined?) and RAILS_ENV (if defined?)
    attr_accessor :app

    def app
      unless @app and @app.respond_to?:call
        if File.file? 'config.ru'
          @app = Rack::Builder.new { eval(File.read('config.ru')) }
        elsif defined?RAILS_ENV and defined?RAILS_ROOT
          raise "You need the Rack::Adapter::Rails to run Rails apps with RackBox." + 
                " Try: sudo gem install thin" unless defined?Rack::Adapter::Rails
          @app = Rack::Adapter::Rails.new :root => RAILS_ROOT, :environment => RAILS_ENV
        else
          raise "RackBox.app not configured."
        end
      end
      @app
    end

    # helper method for taking a Hash of params and turning them into POST params
    #
    # >> RackBox.build_query :hello => 'there'
    # => 'hello=there'
    #
    # >> RackBox.build_query :hello => 'there', :foo => 'bar'
    # => 'hello=there&foo=bar' 
    #
    # >> RackBox.build_query :user => { :name => 'bob', :password => 'secret' }
    # => 'user[name]=bob&user[password]=secret' 
    #
    def build_query params_hash = { }
      # check to make sure no values are Hashes ...
      # if they are, we need to flatten them!
      params_hash.each do |key, value|
        # params_hash  :a => { :b => X, :c => Y }
        # needs to be  'a[b]' => X, 'a[b]' => Y
        if value.is_a? Hash
          inner_hash = params_hash.delete key # { :b => X, :c => Y }
          inner_hash.each do |subkey, subvalue|
            new_key = "#{ key }[#{ subkey }]" # a[b] or a[c]
            puts "warning: overwriting query parameter #{ new_key }" if params_hash[new_key]
            params_hash[new_key] = subvalue # 'a[b]' => X or a[c] => Y
          end
          # we really shouldn't keep going thru the #each now that we've altered data!
          return build_query(params_hash)
        end
      end
      Rack::Utils.build_query params_hash
    end

  end
end
