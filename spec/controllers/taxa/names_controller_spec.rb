require File.dirname(__FILE__) + '/../../spec_helper'

describe Taxa::NamesController do

  before(:all) do
    truncate_all_tables
    load_scenario_with_caching :testy
    @testy = EOL::TestInfo.load('testy')
  end

  shared_examples_for 'taxa/names controller' do
    it 'should instantiate section for assistive header' do
      assigns[:assistive_section_header].should be_a(String)
    end
    it 'should instantiate the taxon concept' do
      assigns[:taxon_concept].should == @testy[:taxon_concept]
    end
    it 'should instantiate hierarchies' do
      get :show, :taxon_id => @testy[:taxon_concept].id.to_i
      assigns[:hierarchies].should == @testy[:taxon_concept].published_hierarchy_entries.collect{|he| he.hierarchy if he.hierarchy.browsable?}.uniq
    end
  end


  describe 'GET index' do # default related names
    before :each do
      get :index, :taxon_id => @testy[:taxon_concept].id.to_i
    end
    it_should_behave_like 'taxa/names controller'
    it 'should instantiate related names' do
      assigns[:related_names].should be_a(Hash)
      assigns[:related_names]['parents'].should be_a(Array)
      assigns[:related_names]['children'].should be_a(Array)
    end
  end

  describe 'POST names' do
    it 'should add a new common name'
  end

  describe 'GET common_names' do
    before :each do
      get :common_names, :taxon_id => @testy[:taxon_concept].id.to_i
    end
    it_should_behave_like 'taxa/names controller'
    it 'should instantiate common names' do
      assigns[:common_names].should be_a(Array)
      assigns[:common_names].first.should be_a(EOL::CommonNameDisplay)
    end
  end

  describe 'GET synonyms' do
    before :each do
      get :synonyms, :taxon_id => @testy[:taxon_concept].id.to_i
    end
    it_should_behave_like 'taxa/names controller'
    it 'should preload synonym associations' do
      assigns[:taxon_concept].published_hierarchy_entries.first.scientific_synonyms.should be_a(Array)
      assigns[:taxon_concept].published_hierarchy_entries.first.scientific_synonyms.first.should be_a(Synonym)
    end
  end

end