# Build the DataObjects Solr core. ...Perhaps this all belongs on that class,
# but I think that's a little heavy. NOTE: At the time of this writing, on my
# personal machine, this ran at about 200 entries per second. We have over 1
# BILLION objects in production, so if you were ever crazy enough to run this in
# prod, you would probably have a wait of about 57 DAYS. You have been warned!
describe DataObject::Indexer do
  describe "#by_data_object_ids" do
    before(:all) do
      populate_tables(:vetted, :visibilities, :licenses, :data_types,
        :activities, :changeable_object_types, :content_partner_statuses)
      Language.create_english
      @object = DataObject.gen(data_subtype_id: 4325, data_rating: 3.145)
      @resource = Resource.gen
      event = HarvestEvent.gen(resource: @resource)
      DataObjectsHarvestEvent.gen(harvest_event: event, data_object: @object)
      @dotoc = DataObjectsTableOfContent.gen(data_object: @object)
      @translation_of = DataObject.gen()
      DataObjectTranslation.gen(original_data_object: @translation_of,
        data_object: @object)
      @trusted_assoc = DataObjectsHierarchyEntry.gen(data_object: @object,
        vetted: Vetted.trusted)
      @unreviewed_assoc = DataObjectsHierarchyEntry.gen(data_object: @object,
        vetted: Vetted.unknown)
      @untrusted_assoc = DataObjectsHierarchyEntry.gen(data_object: @object,
        vetted: Vetted.untrusted)
      @visible_assoc = DataObjectsHierarchyEntry.gen(data_object: @object,
        visibility: Visibility.visible)
      @invisible_assoc = DataObjectsHierarchyEntry.gen(data_object: @object,
        visibility: Visibility.invisible)
      @preview_assoc = DataObjectsHierarchyEntry.gen(data_object: @object,
        visibility: Visibility.preview)
      @curated_assoc =
        CuratedDataObjectsHierarchyEntry.gen(data_object: @object)
      @user_assoc = UsersDataObject.gen(data_object: @object)
      @curation = CuratorActivityLog.gen(changeable_object_type_id:
        ChangeableObjectType.data_object.id, target_id: @object.id)
      @indexer = DataObject::Indexer.new
      @indexer.by_data_object_ids([@object.id])
      @solr = SolrCore::DataObjects.new
      @result = solr.select("data_object_id:#{@object.id}")["response"]["docs"].
        first
    end

    it "should store a bunch of attributes" do
      expect(@result["published"]).to eq(1)
      expect(@result["license_id"]).to eq(@object.license_id)
      expect(@result["language_id"]).to eq(@object.license_id)
      expect(@result["guid"]).to eq(@object.guid)
      # Note that this one COULD be fragile due to filtering of Solr strings,
      # but it's unlikely we'll add filtered characters into the defaults:
      expect(@result["description"]).to eq(@object.description)
      expect(@result["data_type_id"]).to eq(@object.data_type_id)
      expect(@result["data_subtype_id"]).to eq(@object.data_subtype_id)
      expect(@result["data_rating"]).to eq(@object.data_rating)
      expect(@result["created_at"]).to eq(SolrCore.date(@object.created_at))
    end
    # published, license id, language id, guid, description, data type id, data
    # subtype id, data rating, data object id, created at.
    it "should index trusted associations" do
      expect(@result["trusted_ancestor_id"]).
        to include(@trusted_assoc.hierarchy_entry.taxon_concept_id)
    end
    it "should index unreviewed associations" do
      expect(@result["unreviewed_ancestor_id"]).
        to include(@unreviewed_assoc.hierarchy_entry.taxon_concept_id)
    end
    it "should index untrusted associations"
    # ETC, etc... follow that pattern...
    it "should index invisible associations"
    it "should index visible associations"
    it "should index preview associations"
    it "should index curated ancestors"
    # via curated_data_objects_hierarchy_entries
    it "should index user-added ancestors"
    # via users_data_object
    it "should index worklist ignores"
    # LOW-PRIORITY.
    it "should index curations via activities (REALLY?)" do
      expect(@result["curated_by_user_id"]).to
        include(@curation.user_id)
    end
    it "should index resources (Argh. Should be on the table.)" do
      expect(@result["resource_id"]).to eq(@resource.id)
    end
    it "should index TOC items" do
      expect(@result["toc_id"]).to include(@dotoc.toc_id)
    end
    it "should index translations" do
      expect(@result["is_translation"]).to be_true
      # TODO: test a non-translation result and ensure it's false
    end
    # From DataObjectTranslation
    it "should score trusted ancestors with a max_vetted_weight of 5" do
      expect(@result["max_vetted_weight"]).to eq(5)
    end
    it "should score untrusted ancestors with a max_vetted_weight of 3"
    it "should score visible ancestors with a max_visibility_weight of 5"
    it "should score preview ancestors with a max_visibility_weight of 2"
  end
end
