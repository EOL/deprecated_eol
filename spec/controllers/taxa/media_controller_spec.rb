require File.dirname(__FILE__) + '/../../spec_helper'

def do_show
  get :show, :taxon_id => @data[:taxon_concept_id]
end

describe Taxa::MediaController do

  before(:all) do
    truncate_all_tables
    load_scenario_with_caching :media_heavy
    @data = EOL::TestInfo.load('media_heavy')
    @first_image = @data[:taxon_concept].images.first
    @first_video = @data[:taxon_concept].videos.first
  end

  describe 'GET show' do

    it 'should instantiate an Array of DataObjects' do
      do_show
      assigns(:media).should be_a(Array)
      assigns(:media).first.should be_a(DataObject)
    end
    it 'should include images in the instantiated Array of DataObjects' do
      do_show
      assigns(:media).include?(@first_image).should be_true
    end

    it 'should include videos in the instantiated Array of DataObjects' do
      get :show, :taxon_id => @data[:taxon_concept_id], :page => 2
      assigns(:media).include?(@first_video).should be_true
    end
    it 'should include sounds in the instantiated Array of DataObjects'
    it 'should paginate instantiated Array of DataObjects' do
      do_show
      assigns(:media).should be_a(WillPaginate::Collection)
    end
    it 'should sort media by rating'
  end

end
