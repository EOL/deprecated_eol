require File.dirname(__FILE__) + '/../spec_helper'

describe Resource do

  before(:all) do
    load_foundation_cache
    iucn_user = User.find_by_given_name('IUCN')
    iucn_content_partner = ContentPartner.find_by_user_id(iucn_user.id)
    @iucn_resource1 = Resource.gen(:content_partner => iucn_content_partner)
    @iucn_resource2 = Resource.gen(:content_partner => iucn_content_partner)
    content_partner = ContentPartner.gen(:user => User.gen)
    @resource = Resource.gen(:content_partner => content_partner)
    HarvestEvent.delete_all
    @oldest_published_harvest_event = HarvestEvent.gen(:resource => @resource, :published_at => 3.hours.ago)
    @latest_published_harvest_event = HarvestEvent.gen(:resource => @resource, :published_at => 2.hours.ago)
    @latest_unpublished_harvest_event = HarvestEvent.gen(:resource => @resource, :published_at => nil)
  end

  before(:each) { @resource = Resource.find(@resource) } # Reload, for some reason, wasn't cutting the mustard.

  it "should return the resource's oldest published harvest event" do
    @resource.oldest_published_harvest_event.should == @oldest_published_harvest_event
  end

  it "should return the resource's latest published harvest event" do
    @resource.latest_published_harvest_event.should == @latest_published_harvest_event
  end

  it "should return the resource's latest harvest event" do # NOTE - ordered by id, so...
    unless @resource.latest_harvest_event == @latest_unpublished_harvest_event
      puts "** Weird problem, not always reproducible: this usually works. Why didn't it work this time?"
      puts "** UPDATE: still not sure. See, I can call the same code that's in the method:"

      # (rdb:1) p @resource.latest_harvest_event
      # #<HarvestEvent id: 3, resource_id: 5, began_at: "2013-08-15 08:26:52", completed_at: "2013-08-15 09:26:52", published_at: "2013-08-15
      # 11:26:52", publish: false>
      # (rdb:1) p HarvestEvent.where(resource_id: 5).last || 0
      # #<HarvestEvent id: 4, resource_id: 5, began_at: "2013-08-15 08:26:52", completed_at: "2013-08-15 09:26:52", published_at: nil, publish: false>

      # ...And it's not cache, either: I rand Rails.cache.clear before this. (though, also interesting: after running the method, the cache key
      # doesn't actually appear to exist: 
      # (rdb:1) p Rails.cache.read "test/resources/latest_harvest_event_for_resource_5"
      # nil

      puts "** If you are seeing this, change the { @resource = Resource.find(@resource) } to  { @resource.reload } , because it didn't work."

      debugger
    end
    @resource.latest_harvest_event.should == @latest_unpublished_harvest_event
  end

  it '#iucn returns the last IUCN resource' do
    Resource.iucn.should == @iucn_resource2
  end

end
