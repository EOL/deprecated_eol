require File.dirname(__FILE__) + '/../spec_helper'

describe HarvestEvent do

  before(:all) do
    truncate_all_tables
    load_foundation_cache
    @resource = Resource.first
    @previous_unpublished_harvest_event = HarvestEvent.gen(:resource => @resource, :published_at => nil)
    @latest_unpublished_harvest_event = HarvestEvent.gen(:resource => @resource, :began_at => Time.now,
                                                    :completed_at => Time.now, :published_at => nil)
  end

  it 'should only allow publish to be set on unpublished and most recent harvest events' do
    validation_message = 'is only allowed for the latest harvest event and only if that event is not already published'
    @previous_unpublished_harvest_event.publish = 1
    @previous_unpublished_harvest_event.should_not be_valid
    @previous_unpublished_harvest_event.errors.on(:publish).should eql(validation_message)
    @latest_unpublished_harvest_event.publish = 1
    @latest_unpublished_harvest_event.should be_valid
    @latest_unpublished_harvest_event.published_at = Time.now
    @latest_unpublished_harvest_event.should_not be_valid
    @latest_unpublished_harvest_event.errors.on(:publish).should eql(validation_message)
  end

end