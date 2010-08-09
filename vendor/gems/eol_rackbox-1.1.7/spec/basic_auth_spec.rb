require File.dirname(__FILE__) + '/spec_helper'

describe RackBox, 'basic auth' do

  it 'should be able to add HTTP BASIC AUTH to a request' do
    app = lambda {|env| [200, {}, "i require http basic auth"] }
    app =  Rack::Auth::Basic.new(app){|u,p| u == 'remi' && p == 'testing' }

    RackBox.request( app, '/' ).status.should  == 401
    RackBox.request( app, '/' ).headers.should == { 'WWW-Authenticate' => 'Basic realm=""' }

    # response = RackBox.request( app, '/', 'Authentication' => 'Basic: ^' )

    response = RackBox.request( app, '/', :http_basic_authentication => %w( remi testing ) )
    response.status.should == 200
    response.body.should   == "i require http basic auth"

    # :basic_auth shortcut
    response = RackBox.request( app, '/', :basic_auth => %w( remi testing ) )
    response.status.should == 200
    response.body.should   == "i require http basic auth"

    # :auth shortcut
    response = RackBox.request( app, '/', :auth => %w( remi testing ) )
    response.status.should == 200
    response.body.should   == "i require http basic auth"
  end

end
