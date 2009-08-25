require File.dirname(__FILE__) + '/../spec_helper'

describe 'Taxon Concepts API' do

  Scenario.load :foundation
  
  it 'a call to the URL should create .gz file' do
    file_dir = File.dirname(__FILE__) + "/../../public/content/tc_api.gz"
    
    RackBox.request("/content/tc_api/")
    File.exist?(file_dir).should eql(true)
  end
  
end
