require File.dirname(__FILE__) + '/../spec_helper'

describe TaxonConcept, '#entry' do
  before(:each) do
    @taxon_concept = TaxonConcept.new
    @mock_hierarchy = mock_model(Hierarchy, :id => 2)
    Hierarchy.stub!(:default).and_return(@mock_hierarchy)
    @entry_1 = mock_model(HierarchyEntry, :hierarchy_id => 1) # This is NOT the deafult
    @entry_2 = mock_model(HierarchyEntry, :hierarchy_id => 2) # This is the default
    @taxon_concept.stub!(:hierarchy_entries).and_return([@entry_1, @entry_2])
  end
  it 'should grab the entry from the default hierarchy if available' do
    Hierarchy.should_receive(:default).and_return(@mock_hierarchy)
    @taxon_concept.entry.should == @entry_2
  end
  it 'should grab the first available entry if the default hierarchy entry is missing' do
    @mock_hierarchy.should_receive(:id).and_return(3)
    @taxon_concept.entry.should == @entry_1
  end
  it 'should raise an exception if there are no assoiated HEs... this is impossible' do
    @taxon_concept.should_receive(:hierarchy_entries).at_least(1).times.and_return([])
    lambda { @taxon_concept.entry }.should raise_error
  end
end



describe TaxonConcept, 'iucn methods' do

  fixtures :agents, :taxon_concepts, :resources, :data_objects, :taxon_concepts, :taxon_concept_names, :taxa, :data_objects_taxa, :agents_resources, :resources_taxa

  before :each do
    # fixtures are already loaded at this point.
    @he = mock_model(HierarchyEntry)
    cn  = mock_model(CanonicalForm)
    cn.stub!(:string).and_return('foo')
    @he.stub!(:content_level).and_return(4)
    @he.stub!(:name).and_return(Name.new(:italicized => '<i>foo</i>', :string => 'foo', :canonical_form => cn))
    @he.stub!(:media).and_return({:video => false, :map => false, :images => false})
    @he.stub!(:ancestors).and_return([])
    @he.stub!(:kingdom).and_return(nil)
    @he.stub!(:children).and_return([])
    @he.stub!(:images).and_return([])
    @he.stub!(:videos).and_return([])
    @he.stub!(:map).and_return(nil)
  end
  
  it 'should populate iucn_conservation_status and iucn_conservation_status_url' do
# has many taxa, and one resource is associated with it. 
    taxon = TaxonConcept.find(taxon_concepts(:cafeteria).id)
    taxon.iucn_conservation_status_url.should == agents(:iucn).homepage
    taxon.iucn_conservation_status.should == data_objects(:cafeteria_iucn).description
  end
  
end

describe TaxonConcept, 'without fixtures' do

  before(:each) do
    @mock_hierarchy = mock_model(Hierarchy)
    @taxon_concept = TaxonConcept.new
    @mock_he = mock_model(HierarchyEntry)
    @mock_he.stub!(:hierarchy_id).and_return(@mock_hierarchy.id)
    # We create an array of entries just to test that we'll find the one in the middle:
    he1 = mock_model(HierarchyEntry); he1.stub!(:hierarchy_id).and_return(@mock_hierarchy.id + 1)
    he2 = mock_model(HierarchyEntry); he2.stub!(:hierarchy_id).and_return(@mock_hierarchy.id + 2)
    @taxon_concept.hierarchy_entries = [he1, @mock_he, he2]
  end

  it 'should use italicized name for title by default'
  it 'should use entry\'s "expert" name for title by if TCN is missing'

  it 'should find mappings by name_id' do
    mock_name  = mock_model(Name)
    mock_map_1 = mock_model(Mapping)
    mock_map_2 = mock_model(Mapping)
    Mapping.should_receive(:find_by_sql).and_return([mock_map_1, mock_map_2])
    @taxon_concept.mappings.should == [mock_map_1, mock_map_2]
  end

  it '#ping_host_urls should grab ping_host_urls from mappings' do
    mock_map_1  = mock_model(Mapping)
    mock_map_2  = mock_model(Mapping)
    mock_map_1.should_receive(:ping_host?).and_return(true)
    mock_map_2.should_receive(:ping_host?).and_return(true)
    mock_map_1.should_receive(:ping_host_url).and_return('one')
    mock_map_2.should_receive(:ping_host_url).and_return('two')
    mock_map_1.should_receive(:collection).and_return(['doesnt matter'])
    mock_map_2.should_receive(:collection).and_return(['doesnt matter'])
    @taxon_concept.should_receive(:mappings).and_return([mock_map_1, mock_map_2])
    @taxon_concept.ping_host_urls.should == ['one', 'two']
  end

  it 'should use common name for subtitle by default'
  it 'should use the user\'s language for common-name subtitle'
  it 'should use italicized canonical name for subtitle if there is no common name'
  it 'should use (non-ital) canonical name for subtitle if there is no common name and no italicized form'
  it 'should use entry\'s common name for subtitle if there is no TCN vernacular and no canonical'

end

describe TaxonConcept, 'with fixtures' do

  fixtures :collections, :data_objects, :data_objects_taxa, :data_objects_table_of_contents, :taxa, :hierarchies,
    :mappings, :hierarchy_entries, :names, :toc_items, :synonyms, :synonym_relations, :canonical_forms, :taxon_concepts

  before(:each) do
    @seabream_id         = taxon_concepts(:seabream).id
    @seabream_overview   = DataObject.find(data_objects(:seabream_overview).id)
    @fishbase_collection = Collection.find(collections(:fishbase).id)
    @seabream = TaxonConcept.find(@seabream_id)
    # Because I'm going to muck with the HEs:
    @seabream.hierarchy_entries = [hierarchy_entries(:seabream)]
  end

  it 'should have the correct kingdom' do
    @seabream.kingdom.id.should == hierarchy_entries(:animalia).id
  end

  it 'should delegate name to entry if possible'
  it 'should delegate name to first hierarchy_entry if no entry exists in default hierarchy'

  it 'should know catalog of life synonyms' do
    col_synonyms = toc_items(:table_of_contents_234)
    results = @seabream.content_by_category(col_synonyms.id)
    results[:synonyms].should include_id_of(synonyms(:seabream_synonym_1))
    results[:synonyms].should include_id_of(synonyms(:seabream_synonym_2))
    results[:synonyms].should include_id_of(synonyms(:seabream_synonym_3))
    results[:synonyms].should_not include_id_of(synonyms(:seabream_synonym_4)) # Because 4 is a common name, stored elsewhere.
  end

end

describe TaxonConcept, 'searches' do
  fixtures :taxon_concepts, :taxon_concept_names, :hierarchy_entries, :names, :hierarchies_content, :normalized_names, :normalized_links
  before :each do
    (@cafeteria, @roenbergensis, @fenchel, theand, thedj, @patterson) = names(:cafeteria_long).string.split.collect {|ea| ea.downcase }
  end
  
  it 'should find cafeteria quickly (T < 0.02) on a search' do
    start = Time.now
    results = TaxonConcept.search(@cafeteria)
    results[:scientific].should_not be_nil
    results[:scientific].should include_id_of(taxon_concepts(:cafeteria)) 
    (start - Time.now).should < 0.02
  end
  
  it 'should find "cafet*" on a search' do
    results = TaxonConcept.search(@cafeteria[0..4] + '*')
    results[:scientific].should_not be_nil
    results[:scientific].should include_id_of(taxon_concepts(:cafeteria)) 
  end
  
  it 'should find "cafeteria and roenbergesnsis" on a search' do
    results = TaxonConcept.search(@cafeteria + ' and ' + @roenbergensis)
    results[:scientific].should_not be_nil
    results[:scientific].should include_id_of(taxon_concepts(:cafeteria)) 
  end
  
  it 'should ignore all kinds of symbols on a search' do
    results = TaxonConcept.search(@cafeteria + '!@#$%^&()[]{}\\\|=+\'"')
    results[:scientific].should_not be_nil
    results[:scientific].should include_id_of(taxon_concepts(:cafeteria)) 
  end
  
  it 'should ignore padding spaces a search' do
    results = TaxonConcept.search("    #{@cafeteria}    \t\n")
    results[:scientific].should_not be_nil
    results[:scientific].should include_id_of(taxon_concepts(:cafeteria)) 
  end

  it 'should find by canonical parts' do
    results = TaxonConcept.search(@cafeteria)
    results[:scientific].should_not be_nil
    results[:scientific].should include_id_of(taxon_concepts(:cafeteria)) 
    results = TaxonConcept.search(@roenbergensis)
    results[:scientific].should_not be_nil
    results[:scientific].should include_id_of(taxon_concepts(:cafeteria)) 
  end
  
  it 'should NOT find by full name parts (that is, authorship parts)' do
    results = TaxonConcept.search(@fenchel) # We should know that our spec fixture don't have any genususesesess like this
    results[:scientific].empty?.should be_true
    results = TaxonConcept.search(@patterson)
    results[:scientific].empty?.should be_true
  end

  it 'should separate scientific and common results' do
    results = TaxonConcept.search(names(:indicus).string)
    results[:scientific].should_not be_nil
    results[:scientific].should include_id_of(taxon_concepts(:seabream))
    results = TaxonConcept.search(names(:karenteen_seabream).string)
    results[:common].should_not be_nil
    results[:common].should include_id_of(taxon_concepts(:seabream))
  end
  
  it 'should require three characters on wildcard searches' do
    results = TaxonConcept.search('ca*')
    results[:errors].should_not be_nil
    results[:errors][0].should =~ /three/
    results = TaxonConcept.search('c*')
    results[:errors].should_not be_nil
    results[:errors][0].should =~ /three/
    results = TaxonConcept.search('caf*')
    results[:errors].should be_nil
  end
  
end

describe TaxonConcept, 'curation' do

  it 'should delegate approved curators to h_e and return a unique list' do
    t_c = TaxonConcept.new
    curator_1 = mock_model(Agent)
    curator_2 = mock_model(Agent)
    curator_3 = mock_model(Agent)
    curator_4 = mock_model(Agent)
    he_1 = mock_model(HierarchyEntry, :approved_curators => [curator_1, curator_2])
    he_2 = mock_model(HierarchyEntry, :approved_curators => [curator_2, curator_3])
    he_3 = mock_model(HierarchyEntry, :approved_curators => [curator_2, curator_3, curator_4])
    t_c.should_receive(:hierarchy_entries).and_return([he_1, he_2, he_3])
    approved = t_c.approved_curators
    approved.should include_id_of(curator_1)
    approved.should include_id_of(curator_2)
    approved.should include_id_of(curator_3)
    approved.should include_id_of(curator_4)
    approved.length.should == approved.map {|c| c.id }.uniq.length # No duplicates
  end
  
end

  
# == Schema Info
# Schema version: 20081020144900
#
# Table name: taxon_concepts
#
#  id             :integer(4)      not null, primary key
#  supercedure_id :integer(4)      not null

