require File.dirname(__FILE__) + '/../spec_helper'

describe Mapping do

  before(:each) do
    @collection = mock_model(Collection)
    @name       = mock_model(Name)
    @fk         = '665'
    @mapping    = Mapping.create(:collection_id => @collection.id, :name_id => @name.id, :foreign_key => @fk)
  end

  it 'should delegate #ping_host? to collection' do
    @collection.should_receive(:ping_host?).and_return('test')
    @mapping.should_receive(:collection).and_return(@collection)
    @mapping.ping_host?.should == 'test'
  end

  it '#ping_host_url should replace %ID% with our FK' do
    @collection.should_receive(:ping_host_url).and_return('Some test with %ID% in it')
    @mapping.should_receive(:collection).and_return(@collection)
    @mapping.ping_host_url.should == "Some test with #{@fk} in it"
  end

end

# == Schema Info
# Schema version: 20081020144900
#
# Table name: mappings
#
#  id            :integer(4)      not null, primary key
#  collection_id :integer(3)      not null
#  name_id       :integer(4)      not null
#  foreign_key   :string(600)     not null

