require File.dirname(__FILE__) + '/../../spec_helper'

def details_do_index
  get :index, :taxon_id => @testy[:taxon_concept].id.to_i
end

describe Taxa::DetailsController do

  before(:all) do
    truncate_all_tables
    load_scenario_with_caching :testy
    @testy = EOL::TestInfo.load('testy')
    EOL::Solr::DataObjectsCoreRebuilder.begin_rebuild
  end

  describe 'GET index' do

    it 'should instantiate the taxon concept' do
      details_do_index
      assigns[:taxon_concept].should be_a(TaxonConcept)
    end
    it 'should instantiate the details Array containing text data objects and special content' do
      details_do_index
      assigns[:taxon_page].text.should be_a(Array)
      assigns[:taxon_page].text.take_while{|d| d.should be_a(DataObject)}.should == assigns[:taxon_page].text
    end
    it 'should instantiate an assistive header' do
      details_do_index
      assigns[:assistive_section_header].should be_a(String)
    end

  end

  describe 'GET set_article_as_exemplar' do

    it 'should throw error if user is not logged in' do
      expect{ get :set_article_as_exemplar, {:taxon_id => @testy[:taxon_concept].id.to_i, 
                  :data_object_id => @testy[:overview].id.to_i} }.to raise_error(EOL::Exceptions::SecurityViolation)
    end

    it 'should throw error if user is not curator' do
      session[:user_id] = @testy[:user].id
      expect{ get :set_article_as_exemplar, {:taxon_id => @testy[:taxon_concept].id.to_i, 
                  :data_object_id => @testy[:overview].id.to_i} }.to raise_error(EOL::Exceptions::SecurityViolation)
    end

    it 'should instantiate the taxon concept and the data object' do
      session[:user_id] = @testy[:curator].id
      text_id = @testy[:taxon_concept].data_objects.select{ |d| d.is_text? }.first.id
      get :set_article_as_exemplar, :taxon_id => @testy[:taxon_concept].id.to_i, :data_object_id => text_id
      assigns[:taxon_concept].should be_a(TaxonConcept)
      assigns[:data_object].should be_a(DataObject)
    end

  end

end
