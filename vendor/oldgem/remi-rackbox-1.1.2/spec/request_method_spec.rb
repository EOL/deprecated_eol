require File.dirname(__FILE__) + '/spec_helper'

describe RackBox, '#request' do

  before do
    @rack_app = lambda {|env| [ 200, { }, "you requested path #{ env['PATH_INFO'] }" ] }  
  end

  it 'should be easy to run the #request method against any Rack app' do
    RackBox::App.new(@rack_app).request('/hello').body.should include('you requested path /hello')
  end

  it 'should be even easier to run the #request method against any Rack app' do
    RackBox.request(@rack_app, '/hello').body.should include('you requested path /hello')
  end

  it "should default to using RackBox.app if an app isn't passed" do
    lambda { RackBox.request('/hello') }.should raise_error
    RackBox.app = @rack_app
    RackBox.request('/hello').body.should include('you requested path /hello')
  end

end
