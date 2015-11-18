require "spec_helper"

describe DataObjectsTaxonConceptsDenormalizer do

  before(:all) do
    truncate_all_tables
    License.create_enumerated
    DataType.create_enumerated
    Visibility.create_enumerated
    Vetted.create_enumerated
    preview_id = Visibility.get_preview.id
    @taxon_1 = TaxonConcept.gen(supercedure_id: 0)
    @taxon_2 = TaxonConcept.gen(supercedure_id: 0)
    he_1 = HierarchyEntry.gen(taxon_concept_id: @taxon_1.id )
    he_2 = HierarchyEntry.gen(taxon_concept_id: @taxon_2.id )
    @do_1 = DataObject.gen(published: 1)
    @do_2 = DataObject.gen(published: 1)
    @do_3 = DataObject.gen(published: 1)
    @do_4 = DataObject.gen(published: 1)
    DataObjectsHierarchyEntry.gen(data_object_id: @do_1.id, hierarchy_entry_id: he_1.id, visibility_id: preview_id)
    DataObjectsHierarchyEntry.gen(data_object_id: @do_2.id, hierarchy_entry_id: he_2.id, visibility_id: preview_id)
    CuratedDataObjectsHierarchyEntry.gen(data_object_id: @do_1.id, hierarchy_entry_id: he_1.id, visibility_id: preview_id)
    CuratedDataObjectsHierarchyEntry.gen(data_object_id: @do_2.id, hierarchy_entry_id: he_2.id, visibility_id: preview_id)
    user = User.gen
    UsersDataObject.gen(data_object_id: @do_3.id, user_id: user.id, taxon_concept_id: @taxon_1.id, visibility_id: preview_id)
    UsersDataObject.gen(data_object_id: @do_4.id, user_id: user.id, taxon_concept_id: @taxon_2.id, visibility_id: preview_id) 
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
    expect(DataObjectsTaxonConcept.find_by_taxon_concept_id_and_data_object_id(@taxon_1.id, @do_1)).not_to be_nil
    expect(DataObjectsTaxonConcept.find_by_taxon_concept_id_and_data_object_id(@taxon_2.id, @do_2)).not_to be_nil
  end
  
  it 'should fill data_objects_taxon_concepts table with approperiate data from curated_data_objects_hierarchy_entries' do
    joins = { hierarchy_entries:{ curated_data_objects_hierarchy_entries: :data_object } }
    visibility_table = "curated_data_objects_hierarchy_entries"
    DataObjectsTaxonConceptsDenormalizer.denormalize_using_joins_via_table(joins, visibility_table)
    expect(DataObjectsTaxonConcept.find_by_taxon_concept_id_and_data_object_id(@taxon_1.id, @do_1)).not_to be_nil
    expect(DataObjectsTaxonConcept.find_by_taxon_concept_id_and_data_object_id(@taxon_2.id, @do_2)).not_to be_nil
  end
  
  it 'should fill data_objects_taxon_concepts table with approperiate data from curated_data_objects_hierarchy_entries' do
    joins = { users_data_objects: :data_object }
    visibility_table = "users_data_objects"
    DataObjectsTaxonConceptsDenormalizer.denormalize_using_joins_via_table(joins, visibility_table)
    expect(DataObjectsTaxonConcept.find_by_taxon_concept_id_and_data_object_id(@taxon_1.id, @do_3)).not_to be_nil
    expect(DataObjectsTaxonConcept.find_by_taxon_concept_id_and_data_object_id(@taxon_2.id, @do_4)).not_to be_nil
  end
  
end