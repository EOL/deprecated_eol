require "spec_helper"

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
  
  describe ".destroy_everything" do
       
    it "should call 'destroy_everything' for data objects" do
      total_data_objects = subject.data_objects
      total_data_objects.count.times { subject.should_receive(:destroy_everything) }
      subject.destroy_everything
    end
    
    it "should call 'destroy_all' for data objects" do
      subject.data_objects.should_receive(:destroy_all)
      subject.destroy_everything
    end
    
    it "should call 'destroy_everything' for hierarchy entries" do
      total_hierarchy_entries = subject.hierarchy_entries
      total_hierarchy_entries.count.times { subject.should_receive(:destroy_everything) }
      subject.destroy_everything
    end
    
    # it "should call 'destroy_all' for data objects harvest event" do
      # DataObjectsHarvestEvent.where(harvest_event_id: subject.id).should_receive(:destroy_all)
      # subject.destroy_everything
    # end
#     
    # it "should call 'destroy_all' for data objects harvest event" do
      # HarvestEventsHierarchyEntry.where(harvest_event_id: subject.id).should_receive(:destroy_all)
      # subject.destroy_everything
    # end
  end

end
