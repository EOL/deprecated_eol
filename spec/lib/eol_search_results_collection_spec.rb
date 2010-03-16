require File.dirname(__FILE__) + '/../spec_helper'

describe EOL::SearchResultsCollection do
  before(:all) do
    Scenario.load :search_with_duplicates
    @tc_id                   = SearchScenarioResults.tc_id
    @new_common_name         = SearchScenarioResults.new_common_name
    @taxon_concept           = SearchScenarioResults.taxon_concept
    @duplicate_taxon_concept = SearchScenarioResults.duplicate_taxon_concept
    @query_results           = SearchScenarioResults.query_results

    @common_collection = EOL::SearchResultsCollection.new(@query_results, :querystring => 'tiger', :type => :common)
    @tc_result         = @common_collection.find {|r| r["id"] == @tc_id }    
    @dup_tc_result     = @common_collection.find {|r| r["id"] == @duplicate_taxon_concept.id }
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
    ancestors = @tc_result['taxon_concept'].ancestors
    parent_concept   = ancestors[-2]
    ancestor_concept = ancestors[-3]
    @tc_result["parent_common"].should   == parent_concept.common_name
    @tc_result["ancestor_common"].should == ancestor_concept.common_name
    @tc_result["parent_scientific"].should   == parent_concept.scientific_name
    @tc_result["ancestor_scientific"].should == ancestor_concept.scientific_name
  end

end
