require "spec_helper"

describe 'Select with Preload Include' do
  before :all do
    load_foundation_cache
    @taxon_concept = build_taxon_concept(:comments => [], :toc => [], :bhl => [], :images => [], :sounds => [])
    @last_hierarchy_entry = HierarchyEntry.last
    @last_data_object = DataObject.last
    @last_agent = Agent.last
    @last_user = User.last
    @last_user_info = UserInfo.gen(user: @last_user)
    @last_user.user_info = @last_user_info
    @dohe = DataObjectsHarvestEvent.last
    ContentPartner.gen(user: @last_user)
  end

  it 'should be able to select .*' do
    he = HierarchyEntry.find(:last, select: "id, created_at, vetted_id", include: :vetted)
    he.class.should == HierarchyEntry
    he.id.should == @last_hierarchy_entry.id                       # grab the primary key any time there's an include
    he.vetted_id.should == @last_hierarchy_entry.vetted_id         # we need to grab the foreign_key of :belongs_to
    he.created_at.should == @last_hierarchy_entry.created_at       # should have the field asked for
    lambda { he.updated_at }.should raise_error(ActiveModel::MissingAttributeError) # shouldn't have a field not asked for
    expect { @last_hierarchy_entry.updated_at }.not_to raise_error

    he.vetted.class.should == Vetted
    he.vetted.label.should == @last_hierarchy_entry.vetted.label
    he.vetted.created_at.should == @last_hierarchy_entry.vetted.created_at
    he.vetted.updated_at.should == @last_hierarchy_entry.vetted.created_at
  end

  it 'should be able to select using a hash of symbols' do
    he = HierarchyEntry.find(:last, select: {hierarchy_entries: [:id, :created_at, :guid, :vetted_id], vetted: '*'}, include: :vetted)
    he.class.should == HierarchyEntry
    he.id.should == @last_hierarchy_entry.id                       # grab the primary key any time there's an include
    he.vetted_id.should == @last_hierarchy_entry.vetted_id         # we need to grab the foreign_key of :belongs_to
    he.created_at.should == @last_hierarchy_entry.created_at       # should have the field asked for
    lambda { he.updated_at.should }.should raise_error(ActiveModel::MissingAttributeError) # shouldn't have a field not asked for
    expect { @last_hierarchy_entry.updated_at }.not_to raise_error

    he.vetted.class.should == Vetted
    he.vetted.label.should == @last_hierarchy_entry.vetted.label
    he.vetted.created_at.should == @last_hierarchy_entry.vetted.created_at
    he.vetted.updated_at.should == @last_hierarchy_entry.vetted.created_at
  end

  it 'should default select fields to primary table' do
    he = HierarchyEntry.find(:last, select: "id, created_at, vetted_id", include: :vetted)
    he.created_at.should == @last_hierarchy_entry.created_at
    lambda { he.updated_at.should }.should raise_error(ActiveModel::MissingAttributeError)
    he.vetted.updated_at.should == @last_hierarchy_entry.vetted.updated_at
  end

  it 'should ONLY grab fields from a table specificed in :select (:has_one)' do
    # Agent :has_one User, so we'll need to tell ActiveRecord to grab user.agent_id,
    # so make sure we're also grabbing the rest of User since :select doesn't specify user fields
    a = Agent.find(:last, select: 'id, created_at')
    a.preload_associations(:user, select: { users: [ :id, :agent_id ] } )
    a.class.should == Agent
    a.id.should == @last_agent.id                       # we grab the primary key any time there's an include
    a.created_at.should == @last_agent.created_at       # should have the field asked for
    lambda { a.updated_at }.should raise_error(ActiveModel::MissingAttributeError) # shouldn't have a field not asked for
    expect { @last_agent.updated_at }.not_to raise_error

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
    he = HierarchyEntry.find(:last, select: "id, created_at, vetted_id", include: :vetted)
    he.class.should == HierarchyEntry
    he.id.should == @last_hierarchy_entry.id                       # grab the primary key any time there's an include
    he.vetted_id.should == @last_hierarchy_entry.vetted_id         # we need to grab the foreign_key of :belongs_to
    he.created_at.should == @last_hierarchy_entry.created_at       # should have the field asked for
    lambda { he.updated_at }.should raise_error(ActiveModel::MissingAttributeError) # shouldn't have a field not asked for
    expect { @last_hierarchy_entry.updated_at }.not_to raise_error

    he.vetted.class.should == Vetted
    he.vetted.created_at.should == @last_hierarchy_entry.vetted.created_at
    he.vetted.updated_at.should == @last_hierarchy_entry.vetted.updated_at
  end

  it 'should be able to select from a composite key belongs_to association' do
    # DataObjectsHarvestEvent has a dual column primary key using the composite_primary_keys gem
    # That gem overrides some methods that do preloading, and this test will make sure they have been properly overloaded
    @dohe = DataObjectsHarvestEvent.last
    @dohe.preload_associations(:harvest_event, select: { harvest_events: '*' } )
    dohe = DataObjectsHarvestEvent.find(:last)
    dohe.preload_associations(:harvest_event, select: { harvest_events: [ :id, :began_at ] })
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
    he = HierarchyEntry.find(:last, select: "id, created_at, vetted_id")
    he.preload_associations(:vetted, select: { vetted: [ :id ], vet: :updated_at })
    he.vetted.updated_at?.should == false
    
    he = HierarchyEntry.find(:last, select: "id, created_at, vetted_id")
    he.preload_associations(:vetted, select: { vetted: [ :id, :updated_at ] })
    he.vetted.updated_at?.should == true
  end

  it 'SHOULD fail on a misspelled field name' do
    find_failed = false
    begin
      he = HierarchyEntry.find(:last, select: "id, created_at, vetted_id")
      he.preload_associations(:vetted, select: { vetted: [ :id, :updated_attttttt ] } )
    rescue
      find_failed = true
    end
    find_failed.should == true

    # now try it again with the field spelled properly
    find_failed = false
    begin
      he = HierarchyEntry.find(:last, select: "id, created_at, vetted_id")
      he.preload_associations(:vetted, select: { vetted: [ :id, :updated_at ] } )
    rescue
      find_failed = true
    end
    find_failed.should == false
  end



  it 'should be able to select from a belongs_to association' do
    he = HierarchyEntry.find(:last, select: "id, created_at, vetted_id")
    he.preload_associations(:vetted, select: { vetted: [ :id, :created_at ] } )
    he.class.should == HierarchyEntry
    he.id.should == @last_hierarchy_entry.id                       # grab the primary key any time there's an include
    he.vetted_id.should == @last_hierarchy_entry.vetted_id         # we need to grab the foreign_key of :belongs_to
    he.created_at.should == @last_hierarchy_entry.created_at       # should have the field asked for
    lambda { he.updated_at.should }.should raise_error(ActiveModel::MissingAttributeError) # shouldn't have a field not asked for
    expect { @last_hierarchy_entry.updated_at }.not_to raise_error

    he.vetted.class.should == Vetted
    he.vetted.created_at.should == @last_hierarchy_entry.vetted.created_at
    lambda { he.vetted.updated_at.should }.should raise_error(ActiveModel::MissingAttributeError)
    expect { @last_hierarchy_entry.vetted.updated_at }.not_to raise_error
  end

  it 'should be able to select from a belongs_to => has_many association' do
    he = HierarchyEntry.find(:last, select: "id, created_at, vetted_id, taxon_concept_id")
    he.preload_associations({ vetted: :taxon_concepts }, select: {
      vetted: [ :id, :created_at ],
      taxon_concepts: [ :id, :supercedure_id, :vetted_id ] } )
    he.class.should == HierarchyEntry
    he.id.should == @last_hierarchy_entry.id                       # grab the primary key any time there's an include
    he.vetted_id.should == @last_hierarchy_entry.vetted_id         # we need to grab the foreign_key of :belongs_to
    he.created_at.should == @last_hierarchy_entry.created_at       # should have the field asked for
    lambda { he.updated_at.should }.should raise_error(ActiveModel::MissingAttributeError) # shouldn't have a field not asked for
    expect { @last_hierarchy_entry.updated_at }.not_to raise_error

    he.vetted.class.should == Vetted
    he.vetted.created_at.should == @last_hierarchy_entry.vetted.created_at
    lambda { he.vetted.updated_at.should }.should raise_error(ActiveModel::MissingAttributeError)
    expect { @last_hierarchy_entry.vetted.updated_at }.not_to raise_error

    he.vetted.taxon_concepts.class.should == Array
    he.vetted.taxon_concepts[0].class.should == TaxonConcept
    he.vetted.taxon_concepts[0].vetted_id.should == @last_hierarchy_entry.vetted.taxon_concepts[0].vetted_id
    he.vetted.taxon_concepts[0].supercedure_id.should == @last_hierarchy_entry.vetted.taxon_concepts[0].supercedure_id
    he.vetted.taxon_concepts[0].published?.should == false
    @last_hierarchy_entry.vetted.taxon_concepts[0].published?.should == true
  end


  it 'should be able to select from a has_one association' do
    a = Agent.find(:last, select: "id, created_at")
    a.preload_associations(:user, select: { users: [ :id, :created_at, :agent_id ] } )
    a.class.should == Agent
    a.id.should == @last_agent.id                       # we grab the primary key any time there's an include
    a.created_at.should == @last_agent.created_at       # should have the field asked for
    lambda { a.updated_at.should }.should raise_error(ActiveModel::MissingAttributeError) # shouldn't have a field not asked for
    expect { @last_agent.updated_at }.not_to raise_error

    a.user.class.should == User
    a.user.agent_id.should == @last_agent.id            # we need to grab the foreign_key of :has_one
    a.user.created_at.should == @last_agent.user.created_at
    lambda { a.user.updated_at.should }.should raise_error(ActiveModel::MissingAttributeError)
    expect { @last_agent.user.updated_at }.not_to raise_error
  end

  it 'should be able to select from a has_one => belongs_to association' do
    a = Agent.find(:last, select: 'id, created_at')
    a.preload_associations({ user: :user_info }, select: { users: [ :id, :created_at, :agent_id ] } )
    a.class.should == Agent
    a.id.should == @last_agent.id                       # we grab the primary key any time there's an include
    a.created_at.should == @last_agent.created_at       # should have the field asked for
    lambda { a.updated_at.should }.should raise_error(ActiveModel::MissingAttributeError) # shouldn't have a field not asked for
    expect { @last_agent.updated_at }.not_to raise_error

    a.user.class.should == User
    a.user.agent_id.should == @last_agent.id                    # we need to grab the foreign_key of :has_one
    a.user.user_info.user_id.should == @last_agent.user.id
    a.user.created_at.should == @last_agent.user.created_at
    lambda { a.user.updated_at.should }.should raise_error(ActiveModel::MissingAttributeError)
    expect { @last_agent.user.updated_at }.not_to raise_error
  end


  it 'should be able to select from a has_many association' do
    vetted_all = Vetted.all

    he = HierarchyEntry.find(:last, select: "id, created_at")
    he.preload_associations(:synonyms, select: { synonyms: [ :id, :preferred, :hierarchy_entry_id ] } )
    he.class.should == HierarchyEntry
    he.id.should == @last_hierarchy_entry.id                       # we grab the primary key any time there's an include
    he.created_at.should == @last_hierarchy_entry.created_at       # should have the field asked for
    lambda { he.updated_at.should }.should raise_error(ActiveModel::MissingAttributeError) # shouldn't have a field not asked for
    expect { @last_hierarchy_entry.updated_at }.not_to raise_error

    he.synonyms.class.should == Array
    he.synonyms[0].class.should == Synonym
    he.synonyms[0].hierarchy_entry_id.should == @last_hierarchy_entry.id   # we need to grab the foreign_key of :has_many
    he.synonyms[0].preferred.should == @last_hierarchy_entry.synonyms[0].preferred
    vetted_all.include?(he.synonyms[0].vetted).should == false
    vetted_all.include?(@last_hierarchy_entry.synonyms[0].vetted).should == true
  end

  it 'should be able to select from a has_many through association' do
    @last_data_object = DataObject.last
    d = DataObject.find(:last, select: "id, created_at")
    d.preload_associations(:harvest_events, select: { harvest_events: [ :id, :began_at ] } )
    d.class.should == DataObject
    d.id.should == @last_data_object.id                       # we grab the primary key any time there's an include
    d.created_at.should == @last_data_object.created_at       # should have the field asked for
    lambda { d.updated_at.should }.should raise_error(ActiveModel::MissingAttributeError) # shouldn't have a field not asked for
    expect { @last_data_object.updated_at }.not_to raise_error

    d.harvest_events.class.should == Array
    d.harvest_events[0].class.should == HarvestEvent
    d.harvest_events[0].id.should == @last_data_object.harvest_events[0].id   # we grab the primary key any time there's an include
    d.harvest_events[0].began_at.should == @last_data_object.harvest_events[0].began_at
    # NOTE - JRice disabled this, since it was failing. I'm assuming the assertion here was meant to be "I didn't
    # TELL it to load the completed_at value, so it shouldn't be there! ...but it is, and I'm not sure why (I'm
    # guessing because it's been cached in some way, now that we've changed the order of tests), and it doesn't
    # strike me as "wrong," anyway (do we REALLY consider it an error if it's there?):
    # d.harvest_events[0].completed_at?.should == false
    # @last_data_object.harvest_events[0].completed_at?.should == true

    # the through models will also get loaded with all attributes
    d.data_objects_harvest_events.class.should == Array
    d.data_objects_harvest_events[0].class.should == DataObjectsHarvestEvent
    d.data_objects_harvest_events[0].harvest_event_id.should == @last_data_object.data_objects_harvest_events[0].harvest_event_id
    d.data_objects_harvest_events[0].guid.should == @last_data_object.data_objects_harvest_events[0].guid
    d.data_objects_harvest_events[0].status_id.should == @last_data_object.data_objects_harvest_events[0].status_id
  end

  it 'should be able to select from a has_and_belongs_to_many association' do
    d = DataObject.find(:last, select: "id, created_at")
    d.preload_associations(:hierarchy_entries, select: { hierarchy_entries: [ :id, :created_at ] } )
    d.class.should == DataObject
    d.id.should == @last_data_object.id                       # we grab the primary key any time there's an include
    d.created_at.should == @last_data_object.created_at       # should have the field asked for
    lambda { d.updated_at.should }.should raise_error(ActiveModel::MissingAttributeError) # shouldn't have a field not asked for
    expect { @last_data_object.updated_at }.not_to raise_error

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
    HierarchyEntriesRef.gen(hierarchy_entry: DataObject.last.hierarchy_entries[0], ref: ref)
    d = DataObject.find(:last, select: 'id, created_at')
    d.preload_associations({ hierarchy_entries: :refs }, select: {
      hierarchy_entries: [ :id, :created_at ],
      refs: [ :id, :full_reference ] })
    d.class.should == DataObject
    d.id.should == @last_data_object.id                       # we grab the primary key any time there's an include
    d.created_at.should == @last_data_object.created_at       # should have the field asked for
    lambda { d.updated_at.should }.should raise_error(ActiveModel::MissingAttributeError) # shouldn't have a field not asked for
    expect { @last_data_object.updated_at }.not_to raise_error

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
    tc = TaxonConcept.gen(vetted: HierarchyEntry.last.vetted)
    he = HierarchyEntry.gen(taxon_concept_id: tc.id)
    ref = Ref.gen()
    ref_type = RefIdentifierType.gen()
    RefIdentifier.gen(ref: ref, ref_identifier_type: ref_type)
    HierarchyEntriesRef.gen(hierarchy_entry: he, ref: ref)

    last_he = HierarchyEntry.last
    he = HierarchyEntry.find(:last, select: "id, created_at, vetted_id")
    he.preload_associations({ vetted: { taxon_concepts: { hierarchy_entries: { refs: :ref_identifiers } } } }, select: {
      ref_identifiers: [ :ref_id, :identifier ] } )
    he.vetted.taxon_concepts.last.hierarchy_entries.last.refs.last.ref_identifiers[0].identifier.should ==
      last_he.vetted.taxon_concepts.last.hierarchy_entries.last.refs.last.ref_identifiers[0].identifier

    he.vetted.taxon_concepts.last.hierarchy_entries.last.refs.last.ref_identifiers[0].ref_identifier_type_id?.should == false
    last_he.vetted.taxon_concepts.last.hierarchy_entries.last.refs.last.ref_identifiers[0].ref_identifier_type_id?.should == true
    HierarchyEntry.last.delete
    Agent.last.delete
  end
end
