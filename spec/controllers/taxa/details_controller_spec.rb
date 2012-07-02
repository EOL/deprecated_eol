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
      assigns[:text_objects].should be_a(Array)
      assigns[:text_objects].take_while{|d| d.should be_a(DataObject)}.should == assigns[:text_objects]
    end
    it 'should instantiate a table of contents' do
      details_do_index
      assigns[:toc_items_to_show].should be_a(Array)
      assigns[:toc_items_to_show].include?(@testy[:overview]).should be_true # TocItem with content should be included
      assigns[:toc_items_to_show].include?(@testy[:toc_item_4]).should be_false # TocItem without content should be excluded
      assigns[:toc_items_to_show].include?(@testy[:education]).should be_false # TocItem from resources and literature tabs should be excluded
    end
    it 'should instantiate an exemplar image'
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
      get :set_article_as_exemplar, :taxon_id => @testy[:taxon_concept].id.to_i, :data_object_id => @testy[:overview].id.to_i
      assigns[:taxon_concept].should be_a(TaxonConcept)
      assigns[:data_object].should be_a(DataObject)
    end

  end

end
