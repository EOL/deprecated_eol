require File.dirname(__FILE__) + '/../../spec_helper'

def details_do_index
  get :index, :taxon_id => @testy[:taxon_concept].id.to_i
end

describe Taxa::DetailsController do

  before(:all) do
    load_foundation_cache
    Vetted.create_enumerated
    @testy = {}
    @testy[:overview] = TocItem.overview
    @testy[:overview_text] = 'This is a test Overview'
    @testy[:image] = FactoryGirl.generate(:image)
    @testy[:taxon_concept] =  build_taxon_concept(images: [{object_cache_url: @testy[:image], data_rating: 2}],
                              toc: [{toc_item: @testy[:overview], description: @testy[:overview_text]}], sname: [], comments: [],
                              flash: [], sounds: [], bhl: [], biomedical_terms: nil)
    @testy[:user] = User.gen
    @testy[:curator] = build_curator(@testy[:taxon_concept] )
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

    it 'should add make an entry in the table of contents for Education Resources objects' do
      taxon_concept = build_taxon_concept(:comments => [], :images => [], :flash => [], :youtube => [], :sounds => [], :toc => [], :bhl => [])
      get :index, :taxon_id => taxon_concept.id
      assigns[:details].resources_links.include?(:education).should == false
      education_object = DataObject.create(data_type: DataType.text, description: 'asd', published: 1)
      taxon_concept.add_object_as_subject(education_object, 'Education Resources')
      get :index, :taxon_id => taxon_concept.id
      debugger unless assigns[:details].resources_links.include?(:education)
      assigns[:details].resources_links.include?(:education).should == true
    end

    it 'should add make an entry in the table of contents for Education objects' do
      taxon_concept = build_taxon_concept(:comments => [], :images => [], :flash => [], :youtube => [], :sounds => [], :toc => [], :bhl => [])
      get :index, :taxon_id => taxon_concept.id
      assigns[:details].resources_links.include?(:education).should == false
      education_object = DataObject.create(data_type: DataType.text, description: 'asd', published: 1)
      taxon_concept.add_object_as_subject(education_object, 'Education')
      get :index, :taxon_id => taxon_concept.id
      assigns[:details].resources_links.include?(:education).should == true
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
