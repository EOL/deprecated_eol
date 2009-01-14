require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

Spec::Runner.configure do |config|
  config.use_transactional_fixtures = false
  config.use_instantiated_fixtures  = true
end

describe Resource do
  before(:each) do
    @resource = Resource.new(:title => 'required', :subject => 'required', :accesspoint_url => "http://www.eol.org", :license_id => 1)
  end

  it "should be invalid without a title" do
    @resource.title = nil
    @resource.should_not be_valid
  end
  
  it "should be invalid without a subject" do
    @resource.subject = nil
    @resource.should_not be_valid
  end

  it "should be invalid without a license_id" do
    @resource.license_id = nil
    @resource.should_not be_valid
  end

  it "should be invalid without an accesspoint_url" do
    @resource.accesspoint_url = nil
    @resource.should_not be_valid
  end

  it "should be valid" do
    @resource.should be_valid
  end
end

describe Resource do 
  fixtures :resources, :data_objects, :harvest_events, :taxa, :data_objects_taxa, :data_objects_harvest_events
  
  describe ".publish" do
  
    before(:each) do
      @resource = resources(:spiders)
    end
    
    after(:each) do
      @resource = nil
    end
  
    def do_publish(a_harvest_event = @resource.harvest_events.last)
      @resource.publish a_harvest_event
    end
    
    
    it "should publish itself" do
      do_publish.should == true
    end
    
    it "should change resource status to Published" do
      do_publish
      @resource.resource_status.should == ResourceStatus.published
    end
    
    
    it "should mark harvest_event data_objects as published" do
      he_count = @resource.harvest_events.count
      do_publish @resource.harvest_events.last
      he_count.should == @resource.harvest_events.count
      data_objects_harvest2 = DataObject.all.select {|d| d.harvest_events.include? @resource.harvest_events.last}
      publish_statuses = data_objects_harvest2.map {|d| d.published}.uniq
      publish_statuses.size.should == 1
      publish_statuses[0].should == true
      
      # old_data_objects =[]
      #       @resource.harvest_events.each do |h|
      #         h.data_objects.each do |d|
      #           old_data_objects << d unless d.harvest_events.include? @resource.harvest_events.last
      #         end
      #       end  
      #       puts old_data_objects.size    
      #       unpublish_statuses = old_data_objects.map {|d| d.published}.uniq
      #       unpublish_statuses.size.should == 1
      #       unpublish_statuses[0].should == false
    end
    
    it "should rollback to older harvest_event when older harvest is published and delete later harvests" do
      he_count = @resource.harvest_events.count
      do_publish @resource.harvest_events.first
      @resource.harvest_events.count.should == he_count - 1
      @resource.harvest_events.first.should == @resource.harvest_events.last
      data_objects_harvest2 = DataObject.all.select {|d| d.harvest_events.include? @resource.harvest_events.first}
      publish_statuses = data_objects_harvest2.map {|d| d.published}.uniq
      publish_statuses.size.should == 1
      publish_statuses[0].should == true      
    end
  
    it "should change preview visibility status to visible for new harvests except ones marked as inappropriate or invisible" do
       do_publish
       data_objects_harvest2 = DataObject.all.select {|d| d.harvest_events.include? @resource.harvest_events.last}
       publish_visibilities = data_objects_harvest2.map {|d| d.visibility_id}.uniq.sort
       publish_visibilities.size.should == 3
       publish_visibilities[0].should == Visibility.invisible.id
       publish_visibilities[1].should == Visibility.visible.id
       publish_visibilities[2].should == Visibility.inappropriate.id       
       DataObject.find(563834099).visibility_id.should == Visibility.invisible.id
       DataObject.find(53454234).visibility.should == Visibility.inappropriate
     end

  end
  
  
  describe "unpublish" do
    
    before(:each) do
      @resource = resources(:spiders)
    end
    
    def do_unpublish(change_resource_status = true)
      @resource.unpublish change_resource_status
    end
    
    it "should unplublish itself" do
      do_unpublish.should == true
    end
    
    it "should have all data_objects of the resource unpublished" do
      do_unpublish
      @resource.harvest_events.each do |h|
        h.data_objects.each do |d|
          d.published.should be_false
        end
      end
    end
    
    it "should change resource status to Processed" do
      do_unpublish
      @resource.resource_status.should == ResourceStatus.processed
    end
    
    it "should not change resource status if change_resource_status attribute is false" do
      do_unpublish false
      @resource.resource_status.should == ResourceStatus.published
    end
    
    it "should change the visibility state for latest harvest to invisible when removing last harvest" do
      @resource.hide_latest_harvest
      @resource.harvest_events.last do |h|
        h.data_objects.each do |d|
          d.visibility.should == Visibility.invisible 
        end
      end      
    end
     
  end
  
  describe "vetting entire resources" do
    
    before(:each) do
      @resource = resources(:spiders)
    end
    
    def do_change_vetted_status(status = 0)
      @resource.set_vetted_status status
    end
    
    it "should update the vetted status" do
      do_change_vetted_status.should == true
    end
    
    it "should change all uncurated data_objects of the resource to unvetted if entire resource is unvetted" do
      DataObject.find(53454294).vetted.should == Vetted.trusted # this data object is curated & trusted, so it's state should not change   
      do_change_vetted_status(0)
      @resource.harvest_events.each do |h|
        h.data_objects.each do |d|
          d.vetted.should == Vetted.unknown unless d.curated
        end
      end
      DataObject.find(53454294).vetted.should == Vetted.trusted # this data object is curated & trusted, so it's state should not change          
    end
    
    it "should change all uncurated data_objects of the resource to vetted if entire resource is vetted" do
      DataObject.find(53454234).vetted.should == Vetted.untrusted # this data object is curated & untrusted, so it's state should not change
      do_change_vetted_status(1)
      @resource.harvest_events.each do |h|
        h.data_objects.each do |d|
          d.vetted.should == Vetted.trusted unless d.curated
        end
      end
      DataObject.find(53454234).vetted.should == Vetted.untrusted # this data object is curated & untrusted, so it's state should not change    
    end
    
  end
  
end
# == Schema Info
# Schema version: 20081020144900
#
# Table name: resources
#
#  id                     :integer(4)      not null, primary key
#  language_id            :integer(2)
#  license_id             :integer(1)      not null
#  resource_status_id     :integer(4)
#  service_type_id        :integer(4)      not null, default(1)
#  accesspoint_url        :string(255)
#  auto_publish           :boolean(1)      not null
#  bibliographic_citation :string(400)
#  dataset_content_type   :string(255)
#  dataset_file_name      :string(255)
#  dataset_file_size      :integer(4)
#  description            :string(255)
#  logo_url               :string(255)
#  metadata_url           :string(255)
#  refresh_period_hours   :integer(2)
#  resource_set_code      :string(255)
#  rights_holder          :string(255)
#  rights_statement       :string(400)
#  service_version        :string(255)
#  subject                :string(255)     not null
#  title                  :string(255)     not null
#  vetted                 :boolean(1)      not null
#  created_at             :timestamp       not null
#  harvested_at           :datetime
#  resource_created_at    :datetime
#  resource_modified_at   :datetime

