require File.dirname(__FILE__) + '/spec_helper'

describe RackBox, 'custom request headers' do

  before do
    @rack_app = lambda {|env| [ 200, { }, env.inspect ] }
  end

  it "#request should take any non-special options and assume they're request headers" do
    RackBox.request(@rack_app, '/').body.should_not include('"HTTP_ACCEPT"=>"application/json"')
    RackBox.request(@rack_app, '/', 'HTTP_ACCEPT' => 'application/json').body.should include('"HTTP_ACCEPT"=>"application/json"')
  end

end
