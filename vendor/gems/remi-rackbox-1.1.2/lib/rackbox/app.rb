class RackBox

  # represents a rack appliction
  #
  # gives us some helpers on a rack app 
  # like the ability to use the #request 
  # method on it easily
  #
  class App
    attr_accessor :rack_app, :mock_request

    def initialize rack_app
      @rack_app = rack_app
      reset_request
    end

    def reset_request
      @mock_request = Rack::MockRequest.new @rack_app
    end
    alias reset reset_request

    # sessions are sticky!
    #
    # to reset, @rackbox_app.reset
    def request url, options = {}
      RackBox.request @mock_request, url, options
    end
  end

end
