require File.dirname(__FILE__) + '/../../spec_helper'

describe 'API:ping' do
  before(:all) do
    truncate_all_tables
  end

  # pings are too frequent (we use them to check site health) and not worth logging
  it 'should NOT create API logs' do
    get_as_xml("/api/ping")
    ApiLog.count.should == 0
  end

  it 'should return XML' do
    response = get_as_xml("/api/ping.xml")
    response.xpath('//response/message').inner_text.should == 'Success'
  end

  it 'should return JSON' do
    response = get_as_json("/api/ping.json")
    response.should ==  { "response" => { "message" => "Success" } }
  end

  it 'should return XML by default when no extension is provided' do
    response = get_as_xml("/api/ping")
    response.xpath('//response/message').inner_text.should == 'Success'
  end
end
