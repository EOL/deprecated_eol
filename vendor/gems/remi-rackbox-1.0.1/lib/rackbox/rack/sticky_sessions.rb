#
# little extension to Rack::MockRequest to track cookies
#
class Rack::MockRequest
  # cookies is a hash of persistent cookies (by domain)
  # that let you test cookies for your app
  #
  # cookies = {
  #    'example.org' => {
  #       'cookie-name' => 'cookie-value',
  #       'chunky' => 'bacon'
  #    }
  # }
  attr_accessor :cookies

  # shortcut to get cookies for a particular domain
  def cookies_for domain
    @cookies ||= {}
    @cookies[ domain ]
  end

  # oh geez ... it looks like i basically copy/pasted this.  there's gotta be a way to do this that's 
  #             more resilient to Rack changes to this method.  i don't like overriding the whole method!
  #
  def request method = "GET", uri = "", opts = { }

    env = self.class.env_for(uri, opts.merge(:method => method))
    
    unless @cookies.nil? or @cookies.empty? or @cookies[env['SERVER_NAME']].nil? or @cookies[env['SERVER_NAME']].empty?
      env['HTTP_COOKIE'] = @cookies[env['SERVER_NAME']].map{ |k,v| "#{ k }=#{ v }" }.join('; ')
    end

    if opts[:lint]
      app = Rack::Lint.new(@app)
    else
      app = @app
    end 

    errors = env["rack.errors"]
    response = Rack::MockResponse.new(*(app.call(env) + [errors]))
    
    if response.original_headers['Set-Cookie']
      @cookies ||= {}
      @cookies[ env['SERVER_NAME'] ] ||= {}
      response.original_headers['Set-Cookie'].map{ |str| /(.*); path/.match(str)[1] }.each do |cookie|
        name, value = cookie.split('=').first, cookie.split('=')[1]
        @cookies[ env['SERVER_NAME'] ][ name ] = value
      end
    end

    response
  end

end
