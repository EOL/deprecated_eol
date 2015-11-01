describe HarvestEvent do
  before(:all) do
    populate_tables(:vetted, :visibilities, :content_partner_statuses,
      :licenses, :data_types, :statuses)
    Rails.cache.clear
    resource = Resource.gen
    @previous_unpublished_harvest_event = HarvestEvent.gen(resource: resource,
      published_at: nil)
    @latest_unpublished_harvest_event = HarvestEvent.gen(resource: resource,
      began_at: Time.now, completed_at: Time.now, published_at: nil)
    @previous_unpublished_harvest_event.resource.reload
    @latest_unpublished_harvest_event.resource.reload
  end

  it 'should only allow publish to be set on unpublished and most recent '\
    'harvest events' do
    validation_message = I18n.t(
      'activerecord.errors.models.harvest_event.attributes.publish.inclusion')
    @previous_unpublished_harvest_event.publish = true
    @previous_unpublished_harvest_event.should_not be_valid
    @previous_unpublished_harvest_event.errors[:publish].first.
      should eql(validation_message)
    @latest_unpublished_harvest_event.publish = true
    Rails.cache.clear
    @latest_unpublished_harvest_event.reload
    @latest_unpublished_harvest_event.should be_valid
  end

  describe ".destroy_everything" do
    it "should call 'destroy_everything' for data objects" do
      total_data_objects = subject.data_objects
      total_data_objects.count.times do
        subject.should_receive(:destroy_everything)
      end
      subject.destroy_everything
    end

    it "should call 'destroy_everything' for hierarchy entries" do
      total_hierarchy_entries = subject.hierarchy_entries
      total_hierarchy_entries.count.times do
        subject.should_receive(:destroy_everything)
      end
      subject.destroy_everything
    end

    describe "#show_preview_objects" do
      subject(:event) { HarvestEvent.gen }
      subject(:other_event) { HarvestEvent.gen(hierarchy: event.hierarchy) }
      let(:preview_object) do
        dohe = DataObjectsHierarchyEntry.gen(visibility: Visibility.preview)
        event.data_objects_harvest_events <<
          DataObjectsHarvestEvent.gen(data_object: dohe.data_object)
        dohe
      end
      let(:preview_object_from_another) do
        dohe = DataObjectsHierarchyEntry.gen(visibility: Visibility.preview)
        other_event.data_objects_harvest_events <<
          DataObjectsHarvestEvent.gen(data_object: dohe.data_object)
          dohe
      end
      let(:invisible_object) do
        dohe = DataObjectsHierarchyEntry.gen(visibility: Visibility.invisible)
        other_event.data_objects_harvest_events <<
          DataObjectsHarvestEvent.gen(data_object: dohe.data_object)
          dohe
      end

      it "makes a preview object from the event visible" do
        expect(preview_object.visibility).to eq(Visibility.preview)
        event.show_preview_objects
        expect(preview_object.reload.visibility).to eq(Visibility.visible)
      end

      it "does NOT make a preview object from another event visible" do
        expect(preview_object_from_another.visibility).to eq(Visibility.preview)
        event.show_preview_objects
        expect(preview_object_from_another.reload.visibility).
          to eq(Visibility.preview)
      end

      it "does NOT make an invisible object visible" do
        expect(invisible_object.visibility).to eq(Visibility.invisible)
        event.show_preview_objects
        expect(invisible_object.reload.visibility).to eq(Visibility.invisible)
      end
    end

    describe "#preserve_invisible" do
      it "should make an invisible data object previously harvested invisible "\
        "again."
      it "should NOT make a visible data object previously harvested invisible"
    end

    describe "#publish_data_objects" do
      it "marks its unpublished data objects as published"
      # NOTE: I would just do this on, say, two data objects.
    end

    describe "#hierarchy_entry_ids_with_ancestors" do
      it "should return all entries associated with the event"
      it "should return all ancestors that are associated of those entries "\
        "and NOT with the event itself"
      # NOTE that this one is required because harvest_events_hierarchy_entries
      # does NOT include all entries that were harvested! (Stupidly; we'll fix
      # that later.) Thus we need to ensure that this method is ALSO returning
      # any "ancestors" that were created in HierarchyEntriesFlattened which
      # were NOT in harvest_events_hierarchy_entries.
    end

    describe "#finish_publishing" do
      it "should publish all hiearchy entries"
      it "should show all hiearchy entries"
      # NOTE: "show" means "make visible"
      it "should publish all associated taxon concepts"
      # NOTE: associated through hierarchy entries.
      it "should publish all synonyms"
      it "should publish flat_ancestor entries"
      # NOTE: this means you will have to create HierarchyEntriesFlattened and
      # ensure that the ancestor entries are published. Two ancestors of one
      # entry is plenty.
      it "should show flat_ancestor entries"
      it "should publish flat_ancestor synonyms"
      # NOTE that those go through the HierarchyEntriesFlattened.
      it "should publish flat_ancestor taxon_concepts"
      # NOTE that these go through TaxonConceptsFlattened.
      it "should return a list of entry ids affected"
      # I would test three, in this case; one of them should be an ancestor.
    end
  end
end
