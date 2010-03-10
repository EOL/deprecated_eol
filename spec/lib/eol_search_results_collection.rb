require File.dirname(__FILE__) + '/../spec_helper'

describe EOL::SearchResultsCollection do
  before(:all) do
    Scenario.load :foundation
    @tc_id = 255
    @old_common_name = 'Old Common Name'
    @new_common_name = 'New Common Name'
    @parent_common_name = 'Parent Name'
    @ancestor_common_name = 'Ancestor Name'
    @ancestor_concept = build_taxon_concept(:common_names => [@ancestor_common_name])
    @parent_concept = build_taxon_concept(:common_names => [@parent_common_name],
                                          :parent_hierarchy_entry_id => @ancestor_concept.entry.id)
    @taxon_concept = build_taxon_concept(:id => @tc_id, :common_names => [@new_common_name],
                                         :parent_hierarchy_entry_id => @parent_concept.entry.id)
    @new_hierarchy = Hierarchy.gen
    @duplicate_taxon_concept = build_taxon_concept(:hierarchy => @new_hierarchy, :common_names => [@old_common_name])
    @query_results =
      [{"common_name"=>["tiger"],
        "top_image_id"=>66,
        "preferred_scientific_name"=>["Nonnumquamerus numquamerus L."],
        "published"=>[true],
        "scientific_name"=>["Nonnumquamerus numquamerus L."],
        "supercedure_id"=>[0],
        "vetted_id"=>[3],
        "taxon_concept_id"=>[25]},
       {"common_name"=>[@old_common_name],
        "top_image_id"=>nil,
        "preferred_scientific_name"=>["Estveroalia nihilata L."],
        "published"=>[true],
        "scientific_name"=>["Estveroalia nihilata L."],
        "supercedure_id"=>[0],
        "vetted_id"=>[0],
        "taxon_concept_id"=>[@tc_id]},
       {"common_name"=>[@old_common_name],
        "top_image_id"=>nil,
        "preferred_scientific_name"=>["Estveroalia nihilata L."],
        "published"=>[true],
        "scientific_name"=>["Estveroalia nihilata L."],
        "supercedure_id"=>[0],
        "vetted_id"=>[0],
        "taxon_concept_id"=>[@duplicate_taxon_concept.id]},
       {"common_name"=>["Tiger moth"],
        "top_image_id"=>51,
        "preferred_scientific_name"=>["Autvoluptatesus temporaalis Linn"],
        "published"=>[true],
        "scientific_name"=>["Autvoluptatesus temporaalis Linn"],
        "supercedure_id"=>[0],
        "vetted_id"=>[3],
        "taxon_concept_id"=>[26]},
       {"common_name"=>["Tiger lilly"],
        "top_image_id"=>nil,
        "preferred_scientific_name"=>["Excepturialia omnisa R. Cartwright"],
        "published"=>[true],
        "scientific_name"=>["Excepturialia omnisa R. Cartwright"],
        "supercedure_id"=>[0],
        "vetted_id"=>[2],
        "taxon_concept_id"=>[27]}]
    @common_collection = EOL::SearchResultsCollection.new(@query_results, :querystring => 'tiger', :type => :common)
    @tc_result = @common_collection.find {|r| r["id"] == @tc_id }    
    @dup_tc_result = @common_collection.find {|r| r["id"] == @duplicate_taxon_concept.id }
  end

  it 'should paginate'

  it 'should add an "id" field to the results' do
    @common_collection.each do |result|
      result["id"].should == result["taxon_concept_id"][0].to_i
    end
  end

  it 'should show "shown as" if the default match was not the best match'

  it 'should load the data object for the best image'

  it 'should mark unknown results'

  it 'should mark untrusted results'

  it 'should convert old-style tag results to new-style results'

  it 'should gracefully handle cases where there is no TaxonConcept for a result'

  it 'should use newer scientific names, if the TC has been updated.'

  it 'should use newer common names, if the TC has been updated.' do
    @tc_result["preferred_common_name"].should == @new_common_name
  end

  it 'should mark duplicates' do
    @tc_result["duplicate"].should be_true
    @dup_tc_result["duplicate"].should be_true
  end

  it 'should show whom duplicate entries are recognized by' do
    @tc_result["recognized_by"].should == @taxon_concept.entry.hierarchy.label
    @dup_tc_result["recognized_by"].should == @duplicate_taxon_concept.entry.hierarchy.label
  end

  it 'should show duplicate entry\'s parent and ancestor' do
    @tc_result["parent"].should   == @parent_concept.common_name
    @tc_result["ancestor"].should == @ancestor_concept.common_name
  end

end
