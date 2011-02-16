require File.dirname(__FILE__) + '/../spec_helper'

describe 'Select with Preload Include' do
  before :all do
    truncate_all_tables
    load_foundation_cache
    @taxon_concept = build_taxon_concept()
    @last_data_object = DataObject.last
    @last_agent = Agent.last
    @dohe = DataObjectsHarvestEvent.last
    ContentPartner.gen(:agent => @last_agent)
  end
  
  it 'should be able to select .*' do
    d = DataObject.find(:last, :select => "data_objects.created_at, vetted.*", :include => :vetted)
    d.class.should == DataObject
    d.id.should == @last_data_object.id                       # grab the primary key any time there's an include
    d.vetted_id.should == @last_data_object.vetted_id         # we need to grab the foreign_key of :belongs_to
    d.created_at.should == @last_data_object.created_at       # should have the field asked for
    d.updated_at.should == nil                                # shouldn't have a field not asked for
    d.updated_at.should_not == @last_data_object.updated_at   # should have the field asked for
    
    d.vetted.class.should == Vetted
    d.vetted.label.should == @last_data_object.vetted.label
    d.vetted.created_at.should == @last_data_object.vetted.created_at
    d.vetted.updated_at.should == @last_data_object.vetted.created_at
  end
  
  it 'should be able to select using a hash of symbols' do
    d = DataObject.find(:last, :select => {:data_objects => [:created_at, :description], :vetted => '*'}, :include => :vetted)
    d.class.should == DataObject
    d.id.should == @last_data_object.id                       # grab the primary key any time there's an include
    d.vetted_id.should == @last_data_object.vetted_id         # we need to grab the foreign_key of :belongs_to
    d.created_at.should == @last_data_object.created_at       # should have the field asked for
    d.updated_at.should == nil                                # shouldn't have a field not asked for
    d.updated_at.should_not == @last_data_object.updated_at   # should have the field asked for
    
    d.vetted.class.should == Vetted
    d.vetted.label.should == @last_data_object.vetted.label
    d.vetted.created_at.should == @last_data_object.vetted.created_at
    d.vetted.updated_at.should == @last_data_object.vetted.created_at
  end
  
  it 'should be able to select using a hash of string' do
    d = DataObject.find(:last, :select => {'data_objects' => ['created_at', 'description'], 'vetted' => '*'}, :include => :vetted)
    d.class.should == DataObject
    d.id.should == @last_data_object.id                       # grab the primary key any time there's an include
    d.vetted_id.should == @last_data_object.vetted_id         # we need to grab the foreign_key of :belongs_to
    d.created_at.should == @last_data_object.created_at       # should have the field asked for
    d.updated_at.should == nil                                # shouldn't have a field not asked for
    d.updated_at.should_not == @last_data_object.updated_at   # should have the field asked for
    
    d.vetted.class.should == Vetted
    d.vetted.label.should == @last_data_object.vetted.label
    d.vetted.created_at.should == @last_data_object.vetted.created_at
    d.vetted.updated_at.should == @last_data_object.vetted.created_at
  end
  
  
  it 'should default select fields to primary table' do
    d = DataObject.find(:last, :select => "created_at, vetted.updated_at", :include => :vetted)
    d.created_at.should == @last_data_object.created_at
    d.updated_at.should == nil
    d.vetted.created_at.should == nil
    d.vetted.updated_at.should == @last_data_object.vetted.updated_at
  end
  
  it 'should ONLY grab fields from a table specificed in :select (:has_one)' do
    # Agent :has_one User, so we'll need to tell ActiveRecord to grab user.agent_id,
    # so make sure we're also grabbing the rest of User since :select doesn't specify user fields
    a = Agent.find(:last, :select => 'agents.created_at', :include => :user)
    a.class.should == Agent
    a.id.should == @last_agent.id                       # we grab the primary key any time there's an include
    a.created_at.should == @last_agent.created_at       # should have the field asked for
    a.updated_at.should == nil                          # shouldn't have a field not asked for
    a.updated_at.should_not == @last_agent.updated_at   # should have the field asked for
    
    a.user.class.should == User
    a.user.agent_id.should == @last_agent.id            # we need to grab the foreign_key of :has_one
    a.user.username?.should == false
    @last_agent.user.username?.should == true
    a.user.family_name?.should == false
    @last_agent.user.family_name?.should == true
    a.user.given_name?.should == false
    @last_agent.user.given_name?.should == true
  end
  
  it 'should ONLY grab fields from a table specificed in :select (:belongs_to)' do
    # DataObject :belongs_to Vetted, so we'll need to tell ActiveRecord to grab data_object.vetted_it,
    # so make sure we're also grabbing the rest of User since :select doesn't specify user fields
    d = DataObject.find(:last, :select => "data_objects.created_at", :include => :vetted)
    d.class.should == DataObject
    d.id.should == @last_data_object.id                       # grab the primary key any time there's an include
    d.vetted_id.should == @last_data_object.vetted_id         # we need to grab the foreign_key of :belongs_to
    d.created_at.should == @last_data_object.created_at       # should have the field asked for
    d.updated_at.should == nil                                # shouldn't have a field not asked for
    d.updated_at.should_not == @last_data_object.updated_at   # should have the field asked for
    
    d.vetted.class.should == Vetted
    d.vetted.created_at?.should == false
    @last_data_object.vetted.created_at == true
    d.vetted.updated_at?.should == false
    @last_data_object.vetted.updated_at == true
  end
  
  it 'should be able to select from a composite key belongs_to association' do
    # DataObjectsHarvestEvent has a dual column primary key using the composite_primary_keys gem
    # That gem overrides some methods that do preloading, and this test will make sure they have been properly overloaded
    dohe = DataObjectsHarvestEvent.find(:last, :select => 'harvest_events.began_at', :include => :harvest_event)
    dohe.class.should == DataObjectsHarvestEvent
    dohe.data_object_id.should == @dohe.data_object_id        # we grab the primary key any time there's an include
    dohe.harvest_event_id.should == @dohe.harvest_event_id    # we grab the primary key any time there's an include
    
    dohe.harvest_event.class.should == HarvestEvent
    dohe.harvest_event.id.should == @dohe.harvest_event.id    # we grab the primary key any time there's an include
    dohe.harvest_event.began_at.should == @dohe.harvest_event.began_at
    dohe.harvest_event.completed_at?.should == false
    @dohe.harvest_event.completed_at?.should == true
  end
  
  it 'should NOT fail on a misspelled table name' do
    d = DataObject.find(:last, :select => "data_objects.created_at, VET.updated_at", :include => :vetted)
    d.vetted.updated_at?.should == false
    
    d = DataObject.find(:last, :select => "data_objects.created_at, vetted.updated_at", :include => :vetted)
    d.vetted.updated_at?.should == true
  end
  
  it 'SHOULD fail on a misspelled field name' do
    find_failed = false
    begin
      DataObject.find(:last, :select => "data_objects.created_at, vetted.updated_attttttt", :include => :vetted)
    rescue
      find_failed = true
    end
    find_failed.should == true
    
    # now try it again with the field spelled properly
    find_failed = false
    begin
      DataObject.find(:last, :select => "data_objects.created_at, vetted.updated_at", :include => :vetted)
    rescue
      find_failed = true
    end
    find_failed.should == false
  end
  
  
  
  it 'should be able to select from a belongs_to association' do
    d = DataObject.find(:last, :select => "data_objects.created_at, vetted.created_at", :include => :vetted)
    d.class.should == DataObject
    d.id.should == @last_data_object.id                       # grab the primary key any time there's an include
    d.vetted_id.should == @last_data_object.vetted_id         # we need to grab the foreign_key of :belongs_to
    d.created_at.should == @last_data_object.created_at       # should have the field asked for
    d.updated_at.should == nil                                # shouldn't have a field not asked for
    d.updated_at.should_not == @last_data_object.updated_at   # should have the field asked for
    
    d.vetted.class.should == Vetted
    d.vetted.created_at.should == @last_data_object.vetted.created_at
    d.vetted.updated_at.should == nil
    d.vetted.updated_at.should_not == @last_data_object.vetted.updated_at
  end
  
  it 'should be able to select from a belongs_to => has_many association' do
    d = DataObject.find(:last, :select => "data_objects.created_at, vetted.created_at, taxon_concepts.supercedure_id", :include => {:vetted => :taxon_concepts})
    d.class.should == DataObject
    d.id.should == @last_data_object.id                       # grab the primary key any time there's an include
    d.vetted_id.should == @last_data_object.vetted_id         # we need to grab the foreign_key of :belongs_to
    d.created_at.should == @last_data_object.created_at       # should have the field asked for
    d.updated_at.should == nil                                # shouldn't have a field not asked for
    d.updated_at.should_not == @last_data_object.updated_at   # should have the field asked for
    
    d.vetted.class.should == Vetted
    d.vetted.created_at.should == @last_data_object.vetted.created_at
    d.vetted.updated_at.should == nil
    d.vetted.updated_at.should_not == @last_data_object.vetted.updated_at
    
    d.vetted.taxon_concepts.class.should == Array
    d.vetted.taxon_concepts[0].class.should == TaxonConcept
    d.vetted.taxon_concepts[0].vetted_id.should == @last_data_object.vetted.taxon_concepts[0].vetted_id
    d.vetted.taxon_concepts[0].supercedure_id.should == @last_data_object.vetted.taxon_concepts[0].supercedure_id
    d.vetted.taxon_concepts[0].published?.should == false
    @last_data_object.vetted.taxon_concepts[0].published?.should == true
  end
  
  
  it 'should be able to select from a has_one association' do
    a = Agent.find(:last, :select => "agents.created_at, users.created_at", :include => :user)
    a.class.should == Agent
    a.id.should == @last_agent.id                       # we grab the primary key any time there's an include
    a.created_at.should == @last_agent.created_at       # should have the field asked for
    a.updated_at.should == nil                          # shouldn't have a field not asked for
    a.updated_at.should_not == @last_agent.updated_at   # should have the field asked for
    
    a.user.class.should == User
    a.user.agent_id.should == @last_agent.id            # we need to grab the foreign_key of :has_one
    a.user.created_at.should == @last_agent.user.created_at
    a.user.updated_at.should == nil
    a.user.updated_at.should_not == @last_agent.user.updated_at
  end
  
  it 'should be able to select from a has_one => belongs_to association' do
    a = Agent.find(:last, :select => "agents.created_at, users.created_at, languages.label", :include => [{:user => :language}])
    a.class.should == Agent
    a.id.should == @last_agent.id                       # we grab the primary key any time there's an include
    a.created_at.should == @last_agent.created_at       # should have the field asked for
    a.updated_at.should == nil                          # shouldn't have a field not asked for
    a.updated_at.should_not == @last_agent.updated_at   # should have the field asked for
    
    a.user.class.should == User
    a.user.agent_id.should == @last_agent.id                    # we need to grab the foreign_key of :has_one
    a.user.language_id.should == @last_agent.user.language_id   # we need to grab the foreign_key of :belongs_to
    a.user.created_at.should == @last_agent.user.created_at
    a.user.updated_at.should == nil
    a.user.updated_at.should_not == @last_agent.user.updated_at
    
    a.user.language.class.should == Language
    a.user.language.id.should == @last_agent.user.language.id   # we grab the primary key any time there's an include
    a.user.language.label.should == @last_agent.user.language.label
    a.user.language.name?.should == false
    @last_agent.user.language.name?.should == true
  end
  
  
  it 'should be able to select from a has_many association' do
    d = DataObject.find(:last, :select => "data_objects.created_at, feed_data_objects.created_at", :include => :feed_data_objects)
    d.class.should == DataObject
    d.id.should == @last_data_object.id                       # we grab the primary key any time there's an include
    d.created_at.should == @last_data_object.created_at       # should have the field asked for
    d.updated_at.should == nil                                # shouldn't have a field not asked for
    d.updated_at.should_not == @last_data_object.updated_at   # should have the field asked for
    
    d.feed_data_objects.class.should == Array
    d.feed_data_objects[0].class.should == FeedDataObject
    d.feed_data_objects[0].data_object_id.should == @last_data_object.id   # we need to grab the foreign_key of :has_many
    d.feed_data_objects[0].created_at.should == @last_data_object.feed_data_objects[0].created_at
    d.feed_data_objects[0].data_type_id?.should == false
    @last_data_object.feed_data_objects[0].data_type_id?.should == true
  end
  
  it 'should be able to select from a has_many through association' do
    d = DataObject.find(:last, :select => "data_objects.created_at, harvest_events.began_at", :include => :harvest_events)
    d.class.should == DataObject
    d.id.should == @last_data_object.id                       # we grab the primary key any time there's an include
    d.created_at.should == @last_data_object.created_at       # should have the field asked for
    d.updated_at.should == nil                                # shouldn't have a field not asked for
    d.updated_at.should_not == @last_data_object.updated_at   # should have the field asked for
    
    d.harvest_events.class.should == Array
    d.harvest_events[0].class.should == HarvestEvent
    d.harvest_events[0].id.should == @last_data_object.harvest_events[0].id   # we grab the primary key any time there's an include
    d.harvest_events[0].began_at.should == @last_data_object.harvest_events[0].began_at
    d.harvest_events[0].completed_at?.should == false
    @last_data_object.harvest_events[0].completed_at?.should == true
    
    # the through models will also get loaded with all attributes
    d.data_objects_harvest_events.class.should == Array
    d.data_objects_harvest_events[0].class.should == DataObjectsHarvestEvent
    d.data_objects_harvest_events[0].harvest_event_id.should == @last_data_object.data_objects_harvest_events[0].harvest_event_id
    d.data_objects_harvest_events[0].guid.should == @last_data_object.data_objects_harvest_events[0].guid
    d.data_objects_harvest_events[0].status_id.should == @last_data_object.data_objects_harvest_events[0].status_id
  end
  
  it 'should be able to select from a has_and_belongs_to_many association' do
    d = DataObject.find(:last, :select => "data_objects.created_at, hierarchy_entries.created_at", :include => :hierarchy_entries)
    d.class.should == DataObject
    d.id.should == @last_data_object.id                       # we grab the primary key any time there's an include
    d.created_at.should == @last_data_object.created_at       # should have the field asked for
    d.updated_at.should == nil                                # shouldn't have a field not asked for
    d.updated_at.should_not == @last_data_object.updated_at   # should have the field asked for
    
    d.hierarchy_entries.class.should == Array
    d.hierarchy_entries[0].class.should == HierarchyEntry
    d.hierarchy_entries[0].id.should == @last_data_object.hierarchy_entries[0].id
    d.hierarchy_entries[0].created_at.should == @last_data_object.hierarchy_entries[0].created_at
    d.hierarchy_entries[0].updated_at?.should == false
    @last_data_object.hierarchy_entries[0].updated_at?.should == true
  end
  
  it 'should be able to select from nested has_and_belongs_to_many associations' do
    # making a reference to find
    ref = Ref.gen()
    HierarchyEntriesRef.gen(:hierarchy_entry => DataObject.last.hierarchy_entries[0], :ref => ref)
    d = DataObject.find(:last, :select => "data_objects.created_at, hierarchy_entries.created_at, refs.full_reference", :include => {:hierarchy_entries => :refs})
    d.class.should == DataObject
    d.id.should == @last_data_object.id                       # we grab the primary key any time there's an include
    d.created_at.should == @last_data_object.created_at       # should have the field asked for
    d.updated_at.should == nil                                # shouldn't have a field not asked for
    d.updated_at.should_not == @last_data_object.updated_at   # should have the field asked for
    
    d.hierarchy_entries.class.should == Array
    d.hierarchy_entries[0].class.should == HierarchyEntry
    d.hierarchy_entries[0].id.should == @last_data_object.hierarchy_entries[0].id
    d.hierarchy_entries[0].created_at.should == @last_data_object.hierarchy_entries[0].created_at
    d.hierarchy_entries[0].updated_at?.should == false
    @last_data_object.hierarchy_entries[0].updated_at?.should == true
    
    d.hierarchy_entries[0].refs.class.should == Array
    d.hierarchy_entries[0].refs[0].class.should == Ref
    d.hierarchy_entries[0].refs[0].id.should == @last_data_object.hierarchy_entries[0].refs[0].id
    d.hierarchy_entries[0].refs[0].full_reference.should == @last_data_object.hierarchy_entries[0].refs[0].full_reference
    d.hierarchy_entries[0].refs[0].visibility_id?.should == false
    @last_data_object.hierarchy_entries[0].refs[0].visibility_id?.should == true
  end
  
  it 'should be able to select from crazy long association chains' do
    # making a reference to find
    tc = TaxonConcept.gen(:vetted => DataObject.last.vetted)
    he = HierarchyEntry.gen(:taxon_concept_id => tc.id)
    ref = Ref.gen()
    ref_type = RefIdentifierType.gen()
    RefIdentifier.gen(:ref => ref, :ref_identifier_type => ref_type)
    HierarchyEntriesRef.gen(:hierarchy_entry => he, :ref => ref)
    
    d = DataObject.find(:last, :select => "data_objects.created_at, ref_identifiers.identifier", :include => {:vetted => {:taxon_concepts => {:hierarchy_entries => {:refs => :ref_identifiers}}}})
    d.vetted.taxon_concepts.last.hierarchy_entries.last.refs.last.ref_identifiers[0].identifier.should ==
      DataObject.last.vetted.taxon_concepts.last.hierarchy_entries.last.refs.last.ref_identifiers[0].identifier
    
    d.vetted.taxon_concepts.last.hierarchy_entries.last.refs.last.ref_identifiers[0].ref_identifier_type_id?.should == false
    DataObject.last.vetted.taxon_concepts.last.hierarchy_entries.last.refs.last.ref_identifiers[0].ref_identifier_type_id?.should == true
  end
  
  
end
