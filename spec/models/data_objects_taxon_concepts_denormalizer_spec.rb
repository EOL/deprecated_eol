require "spec_helper"

describe DataObjectsTaxonConceptsDenormalizer do

  before(:all) do
    User.delete_all  
    TaxonConcept.delete_all  
    HierarchyEntry.delete_all  
    DataObject.delete_all  
    DataObjectsHierarchyEntry.delete_all  
    CuratedDataObjectsHierarchyEntry.delete_all  
    UsersDataObject.delete_all  
    populate_tables(:visibilities, :vetted, :licenses, :data_types)
    user = User.gen
    @taxon_concepts = []
    @hierarchy_entries = []
    @data_objects = []
    for i in 0..3 
      @data_objects << DataObject.gen(published: 1)
    end
    for i in 0..1
      @taxon_concepts << TaxonConcept.gen(supercedure_id: 0)
      @hierarchy_entries << HierarchyEntry.gen(taxon_concept_id: @taxon_concepts[i].id )
      DataObjectsHierarchyEntry.gen(data_object_id: @data_objects[i].id, hierarchy_entry_id: @hierarchy_entries[i].id, visibility_id: Visibility.get_preview.id)
      UsersDataObject.gen(data_object_id: @data_objects[i+2].id, user_id: user.id, taxon_concept_id: @taxon_concepts[i].id, visibility_id: Visibility.get_preview.id)
      CuratedDataObjectsHierarchyEntry.gen(data_object_id: @data_objects[i].id, hierarchy_entry_id: @hierarchy_entries[i].id, visibility_id: Visibility.get_preview.id)
    end
  end
  
  before(:each) do
    DataObjectsTaxonConcept.delete_all  
  end
  
  it 'should fill data_objects_taxon_concepts table with approperiate data' do
    DataObjectsTaxonConceptsDenormalizer.denormalize
    expect(DataObjectsTaxonConcept.all.count).to equal(4)
  end
  
  it 'should fill data_objects_taxon_concepts table with approperiate data from data_objects_hierarchy_entries' do
    joins = { hierarchy_entries: :data_objects }
    visibility_table = "data_objects_hierarchy_entries"
    DataObjectsTaxonConceptsDenormalizer.denormalize_using_joins_via_table(joins, visibility_table)
    expect(DataObjectsTaxonConcept.find_by_taxon_concept_id_and_data_object_id(@taxon_concepts[0].id, @data_objects[0])).not_to be_nil
    expect(DataObjectsTaxonConcept.find_by_taxon_concept_id_and_data_object_id(@taxon_concepts[1].id, @data_objects[1])).not_to be_nil
  end
  
  it 'should fill data_objects_taxon_concepts table with approperiate data from curated_data_objects_hierarchy_entries' do
    joins = { hierarchy_entries:{ curated_data_objects_hierarchy_entries: :data_object } }
    visibility_table = "curated_data_objects_hierarchy_entries"
    DataObjectsTaxonConceptsDenormalizer.denormalize_using_joins_via_table(joins, visibility_table)
    expect(DataObjectsTaxonConcept.find_by_taxon_concept_id_and_data_object_id(@taxon_concepts[0].id, @data_objects[0])).not_to be_nil
    expect(DataObjectsTaxonConcept.find_by_taxon_concept_id_and_data_object_id(@taxon_concepts[1].id, @data_objects[1])).not_to be_nil
  end
  
  it 'should fill data_objects_taxon_concepts table with approperiate data from users_data_objects' do
    joins = { users_data_objects: :data_object }
    visibility_table = "users_data_objects"
    DataObjectsTaxonConceptsDenormalizer.denormalize_using_joins_via_table(joins, visibility_table)
    expect(DataObjectsTaxonConcept.find_by_taxon_concept_id_and_data_object_id(@taxon_concepts[0].id, @data_objects[2])).not_to be_nil
    expect(DataObjectsTaxonConcept.find_by_taxon_concept_id_and_data_object_id(@taxon_concepts[1].id, @data_objects[3])).not_to be_nil
  end
  
end