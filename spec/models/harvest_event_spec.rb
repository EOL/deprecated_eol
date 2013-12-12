require File.dirname(__FILE__) + '/../spec_helper'

describe HarvestEvent do

  before(:all) do
    load_foundation_cache
    resource = Resource.first
    @previous_unpublished_harvest_event = HarvestEvent.gen(resource: resource, published_at: nil)
    @latest_unpublished_harvest_event = HarvestEvent.gen(resource: resource, began_at: Time.now,
                                                    completed_at: Time.now, published_at: nil)
    @previous_unpublished_harvest_event.resource.reload
    @latest_unpublished_harvest_event.resource.reload
    Rails.cache.clear
  end

  it 'should only allow publish to be set on unpublished and most recent harvest events' do
    validation_message = I18n.t 'activerecord.errors.models.harvest_event.attributes.publish.inclusion'
    @previous_unpublished_harvest_event.publish = true
    @previous_unpublished_harvest_event.should_not be_valid
    @previous_unpublished_harvest_event.errors[:publish].first.should eql(validation_message)
    @latest_unpublished_harvest_event.publish = true
    Rails.cache.clear
    @latest_unpublished_harvest_event.reload
    @latest_unpublished_harvest_event.should be_valid
  end

end
