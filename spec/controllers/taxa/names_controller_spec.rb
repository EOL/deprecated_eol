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
  end


  describe 'GET related_names' do # default related names
    before :each do
      get :related_names, :taxon_id => @testy[:taxon_concept].id.to_i
    end
    it_should_behave_like 'taxa/names controller'
    it 'should instantiate related names' do
      assigns[:related_names].should be_a(Hash)
      assigns[:related_names]['parents'].should be_a(Array)
      assigns[:related_names]['children'].should be_a(Array)
    end
  end

  describe 'POST names' do
    before :each do
      session[:user_id] = @testy[:curator].id
      @approved_languages = Language.approved_languages.collect{|l| l.id}
    end
    it 'should add a new common name in approved languages' do
      approved_language_id = @approved_languages.first
      post :create, :name => { :synonym => { :language_id => approved_language_id }, :string => "snake" }, 
                    :commit_add_common_name => "Add name", :taxon_id => @testy[:taxon_concept].id.to_i
      name = Name.find_by_string("snake").should be_true
      TaxonConceptName.find_by_name_id_and_language_id(Name.find_by_string("snake").id, approved_language_id)
      response.should redirect_to(common_names_taxon_names_path(@testy[:taxon_concept].id.to_i))
    end
    it 'should add a new common name in non-approved languages' do
      non_approved_language_id = Language.find(:all, :conditions => ["id NOT IN (?)", @approved_languages]).first.id
      post :create, :name => { :synonym => { :language_id => non_approved_language_id }, :string => "nag" }, 
                    :commit_add_common_name => "Add name", :taxon_id => @testy[:taxon_concept].id.to_i
      name = Name.find_by_string("nag").should be_true
      TaxonConceptName.find_by_name_id_and_language_id(Name.find_by_string("nag").id, non_approved_language_id)
      response.should redirect_to(common_names_taxon_names_path(@testy[:taxon_concept].id.to_i))
    end
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
