require File.dirname(__FILE__) + '/../../spec_helper'

def media_do_show
  get :show, :taxon_id => @data[:taxon_concept_id]
end

describe Taxa::MediaController do

  before(:all) do
    truncate_all_tables
    load_scenario_with_caching :media_heavy
    @data = EOL::TestInfo.load('media_heavy')
    @taxon_concept = @data[:taxon_concept]
    @first_image = @taxon_concept.images.first
    @first_video = @taxon_concept.videos.first
    @poorly_ranked_image = DataObject.find_by_data_rating_and_vetted_id(0, Vetted.unknown.id)
    @highly_rated_unreviewed_image = DataObject.find_by_data_rating_and_vetted_id(5, Vetted.unknown.id)
  end

  describe 'PUT set_as_exemplar' do
    it 'should set an image as exemplar' do
      @taxon_concept.taxon_concept_exemplar_image.should be_nil
      put :set_as_exemplar, :taxon_id => @taxon_concept.id, :data_object_id => @first_image.id
      @taxon_concept.reload
      @taxon_concept.taxon_concept_exemplar_image.data_object_id.should == @first_image.id
    end
  end

  describe 'GET show' do

    it 'should instantiate the taxon concept' do
      media_do_show
      assigns[:taxon_concept].should be_a(TaxonConcept)
    end

    it 'should instantiate an Array of DataObjects' do
      media_do_show
      assigns[:media].should be_a(Array)
      assigns[:media].first.should be_a(DataObject)
    end

    it 'should include images in the instantiated Array of DataObjects' do
      @first_image.should_not be_nil
      media_do_show
      assigns[:media].include?(@first_image).should be_true
    end

    it 'should include videos in the instantiated Array of DataObjects' do
      @first_video.should_not be_nil
      media_do_show
      assigns[:media].include?(@first_video).should be_true
    end

    it 'should include sounds in the instantiated Array of DataObjects'

    it 'should paginate instantiated Array of DataObjects' do
      media_do_show
      assigns[:media].should be_a(WillPaginate::Collection)
    end

    it 'should sort media by ranking' do
      @poorly_ranked_image.should_not be_nil
      get :show, :taxon_id => @taxon_concept.id, :sort_by => 'ranking'
      assigns[:media].first.data_rating.should == 5
      assigns[:media].include?(@poorly_ranked_image).should be_false
    end

    it 'should sort media by newest' do
      @poorly_ranked_image.should_not be_nil
      media_do_show
      assigns[:media].include?(@poorly_ranked_image).should be_false
      get :show, :taxon_id => @taxon_concept.id, :sort_by => 'newest'
      assigns[:media].include?(@poorly_ranked_image).should be_true
    end

    it 'should sort media by status' do
      @highly_rated_unreviewed_image.should_not be_nil
      trusted_count = DataObject.find_all_by_vetted_id(Vetted.trusted.id).count
      trusted_count.should be_a(Fixnum)
      get :show, :taxon_id => @taxon_concept.id, :sort_by => 'vetted'
      assigns[:media].first.vetted.should == Vetted.trusted
      assigns[:media][0..trusted_count].include?(@highly_rated_unreviewed_image).should be_false
      assigns[:media].include?(@highly_rated_unreviewed_image).should be_true
    end

    it 'should filter by type:image' do
      media_do_show
      assigns[:media].collect{|m| m if ! m.is_image?}.compact.should_not be_blank
      get :show, :taxon_id => @taxon_concept.id, :sort_by => 'ranking', :type => ['image']
      assigns[:media].collect{|m| m if ! m.is_image?}.compact.should be_blank
    end

    it 'should filter by type:video' do
      media_do_show
      assigns[:media].collect{|m| m if ! m.is_video?}.compact.should_not be_blank
      get :show, :taxon_id => @taxon_concept.id, :sort_by => 'ranking', :type => ['video']
      assigns[:media].collect{|m| m if ! m.is_video?}.compact.should be_blank
    end

    it 'should filter by type:sound'

    it 'should filter by type:photosynth' do
      photosynths = DataObject.find_all_by_source_url('http://photosynth.net/blah/blah/blah')
      photosynths.should_not be_blank
      media_do_show
      assigns[:media].include?(photosynths).should be_false
      get :show, :taxon_id => @taxon_concept.id, :sort_by => 'ranking', :type => ['photosynth']
      assigns[:media].length.should == photosynths.count
      assigns[:media].include?(photosynths.first).should be_true
    end

    it 'should filter by vetted status and visibility'

    it 'should instantiate an assistive header' do
      media_do_show
      assigns[:assistive_section_header].should be_a(String)
    end
  end

end
