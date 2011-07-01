require File.dirname(__FILE__) + '/../../spec_helper'

def media_do_index
  get :index, :taxon_id => @data[:taxon_concept].id
end

describe Taxa::MediaController do

  before(:all) do
    truncate_all_tables
    load_scenario_with_caching :media_heavy
    @data = EOL::TestInfo.load('media_heavy')
    @taxon_concept = @data[:taxon_concept]
  end

  describe 'PUT set_as_exemplar' do
    it 'should set an image as exemplar' do
      @taxon_concept.taxon_concept_exemplar_image.should be_nil
      exemplar_image = @taxon_concept.images.first.id
      put :set_as_exemplar, :taxon_id => @taxon_concept.id, :data_object_id => exemplar_image.id
      @taxon_concept.reload
      @taxon_concept.taxon_concept_exemplar_image.data_object_id.should == exemplar_image.id
    end
  end

  describe 'GET index' do

    before(:all) do
      @taxon_concept.reload

      # we assume for tests that sort methods on models are working and we are just testing
      # that the controller handles parameters correctly and calls the right sort method

      # rank objects in order: 1 - oldest image; 2 - oldest video; 3 - oldest sound
      # assumes exemplar is nil
      @trusted_count = @taxon_concept.media.select{|m| m.vetted_id == Vetted.trusted.id}.count

      @media = @taxon_concept.media.sort_by{|m| m.id}
      @newest_media = @media.last(10).reverse
      @oldest_media = @media.first(3)

      @newest_image_poorly_rated_trusted = @taxon_concept.images.last
      @oldest_image_highly_rated_unreviewed = @taxon_concept.images.first
      @highly_ranked_image = @taxon_concept.images.second
      @newest_image_poorly_rated_trusted.data_rating = 0
      @newest_image_poorly_rated_trusted.vetted_id = Vetted.trusted.id
      @newest_image_poorly_rated_trusted.save
      @oldest_image_highly_rated_unreviewed.data_rating = 20
      @oldest_image_highly_rated_unreviewed.vetted_id = Vetted.unknown.id
      @oldest_image_highly_rated_unreviewed.visibility_id = Visibility.visible.id
      @oldest_image_highly_rated_unreviewed.save
      @highly_ranked_image.data_rating = 8
      @highly_ranked_image.vetted_id = Vetted.trusted.id
      @highly_ranked_image.visibility_id = Visibility.visible.id
      @highly_ranked_image.save

      @newest_video_poorly_rated_trusted = @taxon_concept.videos.last
      @oldest_video_highly_rated_unreviewed = @taxon_concept.videos.first
      @highly_ranked_video = @taxon_concept.videos.second
      @newest_video_poorly_rated_trusted.data_rating = 0
      @newest_video_poorly_rated_trusted.vetted_id = Vetted.trusted.id
      @newest_video_poorly_rated_trusted.save
      @oldest_video_highly_rated_unreviewed.data_rating = 19
      @oldest_video_highly_rated_unreviewed.vetted_id = Vetted.unknown.id
      @oldest_video_highly_rated_unreviewed.visibility_id = Visibility.visible.id
      @oldest_video_highly_rated_unreviewed.save
      @highly_ranked_video.data_rating = 7
      @highly_ranked_video.vetted_id = Vetted.trusted.id
      @highly_ranked_video.visibility_id = Visibility.visible.id
      @highly_ranked_video.save

      @newest_sound_poorly_rated_trusted = @taxon_concept.sounds.last
      @oldest_sound_highly_rated_unreviewed = @taxon_concept.sounds.first
      @highly_ranked_sound = @taxon_concept.sounds.second
      @newest_sound_poorly_rated_trusted.data_rating = 0
      @newest_sound_poorly_rated_trusted.vetted_id = Vetted.trusted.id
      @newest_sound_poorly_rated_trusted.save
      @oldest_sound_highly_rated_unreviewed.data_rating = 18
      @oldest_sound_highly_rated_unreviewed.vetted_id = Vetted.unknown.id
      @oldest_sound_highly_rated_unreviewed.visibility_id = Visibility.visible.id
      @oldest_sound_highly_rated_unreviewed.save
      @highly_ranked_sound.data_rating = 6
      @highly_ranked_sound.vetted_id = Vetted.trusted.id
      @highly_ranked_sound.visibility_id = Visibility.visible.id
      @highly_ranked_sound.save

      @highly_ranked_text = @taxon_concept.text.first
      @highly_ranked_text.data_rating = 21
      @highly_ranked_text.vetted_id = Vetted.trusted.id
      @highly_ranked_text.visibility_id = Visibility.visible.id
      @highly_ranked_text.save

    end

    it 'should instantiate the taxon concept' do
      media_do_index
      assigns[:taxon_concept].should be_a(TaxonConcept)
    end

    it 'should instantiate an Array of DataObjects' do
      media_do_index
      assigns[:media].should be_a(Array)
      assigns[:media].first.should be_a(DataObject)
    end

    it 'should include images in the instantiated Array of DataObjects' do
      @highly_ranked_image.should_not be_nil
      media_do_index
      assigns[:media].include?(@highly_ranked_image).should be_true
    end

    it 'should include videos in the instantiated Array of DataObjects' do
      @highly_ranked_video.should_not be_nil
      media_do_index
      assigns[:media].include?(@highly_ranked_video).should be_true
    end

    it 'should include sounds in the instantiated Array of DataObjects' do
      @highly_ranked_sound.should_not be_nil
      media_do_index
      assigns[:media].include?(@highly_ranked_sound).should be_true
    end

    it 'should not include text objects in the instantiated Array of DataObjects' do
      @highly_ranked_text.should_not be_nil
      media_do_index
      assigns[:media].include?(@highly_ranked_text).should be_false
    end

    it 'should paginate instantiated Array of DataObjects' do
      media_do_index
      assigns[:media].should be_a(WillPaginate::Collection)
    end

    it 'should sort media by status then rating, which is also the default sort order' do

      highly_ranked = [@highly_ranked_image, @highly_ranked_video, @highly_ranked_sound]
      @trusted_count.should be_a(Fixnum)

      media_do_index
      sorted_by_default = assigns[:media]
      sorted_by_default.first(3).should == highly_ranked
      sorted_by_default.count.should > @trusted_count # because next we assume all trusted objects fit on the first page
      sorted_by_default.include?(@newest_image_poorly_rated_trusted).should be_true
      sorted_by_default.include?(@newest_video_poorly_rated_trusted).should be_true
      sorted_by_default.include?(@newest_sound_poorly_rated_trusted).should be_true

      get :index, :taxon_id => @taxon_concept.id, :sort_by => 'status'
      sorted_by_status = assigns[:media]
      sorted_by_status.should == sorted_by_default
      sorted_by_status.should == DataObject.sort_by_rating(sorted_by_status, [:visibility, :vetted, :rating, :date, :type])

    end

    it 'should sort media by rating then status' do
      @newest_image_poorly_rated_trusted.should_not be_nil
      @newest_video_poorly_rated_trusted.should_not be_nil
      @newest_sound_poorly_rated_trusted.should_not be_nil

      highly_rated_unreviewed = [@oldest_image_highly_rated_unreviewed, @oldest_video_highly_rated_unreviewed, @oldest_sound_highly_rated_unreviewed]

      media_do_index
      sorted_by_default = assigns[:media]
      sorted_by_default.first(3).should_not == highly_rated_unreviewed
      sorted_by_default.include?(@newest_image_poorly_rated_trusted).should be_true
      sorted_by_default.include?(@newest_video_poorly_rated_trusted).should be_true
      sorted_by_default.include?(@newest_sound_poorly_rated_trusted).should be_true

      get :index, :taxon_id => @taxon_concept.id, :sort_by => 'rating'
      sorted_by_rating = assigns[:media]
      sorted_by_rating.first(3).should == highly_rated_unreviewed
      sorted_by_rating.include?(@newest_image_poorly_rated_trusted).should be_false
      sorted_by_rating.include?(@newest_video_poorly_rated_trusted).should be_false
      sorted_by_rating.include?(@newest_sound_poorly_rated_trusted).should be_false
      sorted_by_default.should_not == sorted_by_rating

      sorted_by_rating.should == DataObject.sort_by_rating(sorted_by_rating, [:visibility, :rating, :vetted, :date, :type])

    end

    it 'should sort media by newest' do
      media_do_index
      sorted_by_status = assigns[:media]
      sorted_by_status.first(10).should_not == @newest_media

      get :index, :taxon_id => @taxon_concept.id, :sort_by => 'newest'
      sorted_by_newest = assigns[:media]
      sorted_by_newest.first(10).should == @newest_media
      sorted_by_newest.include?(@oldest_media[0]).should be_false
      sorted_by_newest.include?(@oldest_media[1]).should be_false
      sorted_by_newest.include?(@oldest_media[2]).should be_false
      sorted_by_newest.should_not == sorted_by_status
      sorted_by_newest.should == DataObject.sort_by_rating(sorted_by_newest, [:visibility, :date, :vetted, :rating, :type])
    end

    it 'should filter by type:image' do
      media_do_index
      assigns[:media].select{|m| ! m.is_image?}.compact.should_not be_blank
      get :index, :taxon_id => @taxon_concept.id, :sort_by => 'status', :type => ['image']
      assigns[:media].select{|m| ! m.is_image?}.compact.should be_blank
    end

    it 'should filter by type:video' do
      media_do_index
      assigns[:media].select{|m| ! m.is_video?}.compact.should_not be_blank
      get :index, :taxon_id => @taxon_concept.id, :sort_by => 'status', :type => ['video']
      assigns[:media].select{|m| ! m.is_video?}.compact.should be_blank
    end

    it 'should filter by type:sound' do
      media_do_index
      assigns[:media].select{|m| ! m.is_sound?}.compact.should_not be_blank
      get :index, :taxon_id => @taxon_concept.id, :sort_by => 'status', :type => ['sound']
      assigns[:media].select{|m| ! m.is_sound?}.compact.should be_blank
    end

    it 'should filter by type:photosynth' do
      media_do_index
      assigns[:media].select{|m| ! m.source_url.match /photosynth.net/}.compact.should_not be_blank
      get :index, :taxon_id => @taxon_concept.id, :sort_by => 'status', :type => ['photosynth']
      assigns[:media].select{|m| ! m.source_url.match /photosynth.net/}.compact.should be_blank
    end

    it 'should filter by vetted status and visibility'

    it 'should instantiate an assistive header' do
      media_do_index
      assigns[:assistive_section_header].should be_a(String)
    end
  end

end
