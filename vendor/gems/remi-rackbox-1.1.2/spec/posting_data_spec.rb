require File.dirname(__FILE__) + '/spec_helper'

describe RackBox, 'POSTing data' do

  before do
    @rack_app1 = lambda {|env| [ 200, { }, "you POSTed data: #{ env['rack.input'].read }" ] }  
    @rack_app2 = lambda {|env| 
      req = Rack::Request.new env
      [ 200, { }, "you POSTed data: #{ req.body.read }" ]
    }  
    @method_app = lambda {|env| [ 200, { }, "method: #{ env['REQUEST_METHOD'] }" ] }
  end

  it 'should make it easy to POST data, eg. curl -D "XML"' do
    RackBox.request(@rack_app1, '/', :data => 'hi there').body.should include('you POSTed data: hi there')
    RackBox.request(@rack_app2, '/', :data => 'hi there').body.should include('you POSTed data: hi there')
  end

  it "should default to POST if method isn't explicitly set and we set :data" do
    RackBox.request(@method_app, '/').body.should include('method: GET')
    RackBox.request(@method_app, '/', :method => :put).body.should include('method: PUT')
    RackBox.request(@method_app, '/', :data => 'hi').body.should include('method: POST')
    RackBox.request(@method_app, '/', :data => 'hi', :method => :put).body.should include('method: PUT')
  end

  it "should default to POST if method isn't explicitly set and we set :params" do
    RackBox.request(@method_app, '/').body.should include('method: GET')
    RackBox.request(@method_app, '/', :method => :put).body.should include('method: PUT')
    RackBox.request(@method_app, '/', :params => { :x => 5 }).body.should include('method: POST')
    RackBox.request(@method_app, '/', :params => { :x => 5 }, :method => :put).body.should include('method: PUT')
  end

end
