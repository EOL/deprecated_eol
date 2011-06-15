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
  end
  
  describe '#set_as_exemplar' do
    it 'should set an image as exemplar' do
      @taxon_concept.get_exemplar_image.should_not == @first_image.id
      put :set_as_exemplar, :taxon_concept_id => @taxon_concept.id, :data_object_id => @first_image.id
      @taxon_concept.get_exemplar_image.should == @first_image.id
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
      media_do_show
      assigns[:media].include?(@first_image).should be_true
    end

    it 'should include videos in the instantiated Array of DataObjects (sorting needs to be reviewed)' # do
     #      media_do_show
     #      assigns[:media].include?(@first_video).should be_true
     #    end
    it 'should include sounds in the instantiated Array of DataObjects'
    it 'should paginate instantiated Array of DataObjects' do
      media_do_show
      assigns[:media].should be_a(WillPaginate::Collection)
    end
    
    it 'should filter by type:images and status:trusted (sorting needs to be reviewed)' # do
    #   media_do_show
    #   orig_length = assigns[:media].length
    #   filter_by_type = {}
    #   filter_by_type["image"] = true
    #   filter_by_status = {}
    #   filter_by_status["trusted"]      
    #   filtered_data = DataObject.custom_filter(assigns[:media], filter_by_type, filter_by_status)
    #   filtered_data.first.data_type_id.should == DataType.image.id
    #   filtered_data.last.data_type_id.should == DataType.image.id
    #   filtered_data.first.vetted_id.should == Vetted.trusted.id
    #   filtered_data.last.vetted_id.should == Vetted.trusted.id
    #   filtered_data.length.should < orig_length
    #   #pp filtered_data
    # end

    it 'should filter by type:videos (sorting needs to be reviewed)' # do
    #   media_do_show
    #   orig_length = assigns[:media].length
    #   filter_by_type = {}
    #   filter_by_type["video"] = true
    #   filtered_data = DataObject.custom_filter(assigns[:media], filter_by_type, {})
    #   [DataType.video.id, DataType.youtube.id, DataType.flash.id].include?(filtered_data.first.data_type_id).should be_true
    #   [DataType.video.id, DataType.youtube.id, DataType.flash.id].include?(filtered_data.last.data_type_id).should be_true
    #   filtered_data.length.should < orig_length
    #   #pp filtered_data
    # end

    it 'should sort media by rating' do
      media_do_show
      sorted_data = DataObject.custom_sort(assigns[:media], "rating")
      sorted_data.first.data_rating.should >= sorted_data.last.data_rating
    end
    
    it 'should sort media by newest' do
      media_do_show
      sorted_data = DataObject.custom_sort(assigns[:media], "newest")
      sorted_data.first.id.should >= sorted_data.last.id
    end    
    
    it 'should instantiate an assistive header' do
      media_do_show
      assigns[:assistive_section_header].should be_a(String)
    end
  end

end
