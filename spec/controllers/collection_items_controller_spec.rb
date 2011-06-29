require File.dirname(__FILE__) + '/../spec_helper'

describe CollectionItemsController do

  before(:all) do
    # so this part of the before :all runs only once
    unless User.find_by_username('collections_scenario')
      truncate_all_tables
      load_scenario_with_caching(:collections)
    end
    @test_data = EOL::TestInfo.load('collections')
    @collection_item = @test_data[:collection].collection_items.last
  end

  describe "#update" do
    it "Updates the annotation" do
      getter = lambda{
        post :update, :id => @collection_item.id, :collection_item => {:annotation => "New Annotation"}
        @collection_item.reload
      }
      getter.should change(@collection_item, :annotation)
    end
  end

end