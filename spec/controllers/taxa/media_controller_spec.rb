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
    EOL::Solr::DataObjectsCoreRebuilder.begin_rebuild
  end

  describe 'GET index' do

    before(:all) do
      @taxon_concept.reload

      # we assume for tests that sort methods on models are working and we are just testing
      # that the controller handles parameters correctly and calls the right sort method

      # rank objects in order: 1 - oldest image; 2 - oldest video; 3 - oldest sound
      # assumes exemplar is nil
      taxon_media_parameters = {}
      taxon_media_parameters[:per_page] = 100
      taxon_media_parameters[:data_type_ids] = DataType.image_type_ids + DataType.video_type_ids + DataType.sound_type_ids
      taxon_media_parameters[:return_hierarchically_aggregated_objects] = true
      @trusted_count = @taxon_concept.data_objects_from_solr(taxon_media_parameters).select{ |item|
        item_vetted = item.vetted_by_taxon_concept(@taxon_concept)
        item_vetted.id == Vetted.trusted.id
      }.count

      @media = @taxon_concept.data_objects_from_solr(taxon_media_parameters).sort_by{|m| m.id}
      @newest_media = @media.last(10).reverse
      @oldest_media = @media.first(3)

      @newest_image_poorly_rated_trusted = @taxon_concept.images_from_solr(100).last
      @oldest_image_highly_rated_unreviewed = @taxon_concept.images_from_solr.first
      @highly_ranked_image = @taxon_concept.images_from_solr.second
      @newest_image_poorly_rated_trusted.data_rating = 0
      newest_image_poorly_rated_trusted_association = @newest_image_poorly_rated_trusted.association_for_taxon_concept(@taxon_concept)
      newest_image_poorly_rated_trusted_association.vetted_id = Vetted.trusted.id
      newest_image_poorly_rated_trusted_association.save!
      @newest_image_poorly_rated_trusted.save
      @oldest_image_highly_rated_unreviewed.data_rating = 20
      oldest_image_highly_rated_unreviewed_association = @oldest_image_highly_rated_unreviewed.association_for_taxon_concept(@taxon_concept)
      oldest_image_highly_rated_unreviewed_association.vetted_id = Vetted.unknown.id
      oldest_image_highly_rated_unreviewed_association.save!
      @oldest_image_highly_rated_unreviewed.save
      @highly_ranked_image.data_rating = 8
      highly_ranked_image_association = @highly_ranked_image.association_for_taxon_concept(@taxon_concept)
      highly_ranked_image_association.vetted_id = Vetted.trusted.id
      highly_ranked_image_association.save!
      @highly_ranked_image.save

      @newest_video_poorly_rated_trusted = @taxon_concept.data_objects.select{ |d| d.is_video? }.last
      @oldest_video_highly_rated_unreviewed = @taxon_concept.data_objects.select{ |d| d.is_video? }.first
      @highly_ranked_video = @taxon_concept.data_objects.select{ |d| d.is_video? }.second
      @newest_video_poorly_rated_trusted.data_rating = 0
      newest_video_poorly_rated_trusted_association = @newest_video_poorly_rated_trusted.association_for_taxon_concept(@taxon_concept)
      newest_video_poorly_rated_trusted_association.vetted_id = Vetted.trusted.id
      newest_video_poorly_rated_trusted_association.save!
      @newest_video_poorly_rated_trusted.save
      @oldest_video_highly_rated_unreviewed.data_rating = 19
      oldest_video_highly_rated_unreviewed_association = @oldest_video_highly_rated_unreviewed.association_for_taxon_concept(@taxon_concept)
      oldest_video_highly_rated_unreviewed_association.vetted_id = Vetted.unknown.id
      oldest_video_highly_rated_unreviewed_association.save!
      @oldest_video_highly_rated_unreviewed.save
      @highly_ranked_video.data_rating = 7
      highly_ranked_video_association = @highly_ranked_video.association_for_taxon_concept(@taxon_concept)
      highly_ranked_video_association.vetted_id = Vetted.trusted.id
      highly_ranked_video_association.save!
      @highly_ranked_video.save

      @newest_sound_poorly_rated_trusted = @taxon_concept.data_objects.select{ |d| d.is_sound? }.last
      @oldest_sound_highly_rated_unreviewed = @taxon_concept.data_objects.select{ |d| d.is_sound? }.first
      @highly_ranked_sound = @taxon_concept.data_objects.select{ |d| d.is_sound? }.second
      @newest_sound_poorly_rated_trusted.data_rating = 0
      newest_sound_poorly_rated_trusted_association = @newest_sound_poorly_rated_trusted.association_for_taxon_concept(@taxon_concept)
      newest_sound_poorly_rated_trusted_association.vetted_id = Vetted.trusted.id
      newest_sound_poorly_rated_trusted_association.save!
      @newest_sound_poorly_rated_trusted.save
      @oldest_sound_highly_rated_unreviewed.data_rating = 18
      oldest_sound_highly_rated_unreviewed_association = @oldest_sound_highly_rated_unreviewed.association_for_taxon_concept(@taxon_concept)
      oldest_sound_highly_rated_unreviewed_association.vetted_id = Vetted.unknown.id
      oldest_sound_highly_rated_unreviewed_association.save!
      @oldest_sound_highly_rated_unreviewed.save
      @highly_ranked_sound.data_rating = 6
      highly_ranked_sound_association = @highly_ranked_sound.association_for_taxon_concept(@taxon_concept)
      highly_ranked_sound_association.vetted_id = Vetted.trusted.id
      highly_ranked_sound_association.save!
      @highly_ranked_sound.save

      @highly_ranked_text = @taxon_concept.data_objects.detect{ |d| d.is_text? }
      @highly_ranked_text.data_rating = 21
      highly_ranked_text_association = @highly_ranked_text.association_for_taxon_concept(@taxon_concept)
      highly_ranked_text_association.vetted_id = Vetted.trusted.id
      highly_ranked_text_association.save!
      @highly_ranked_text.save
      EOL::Solr::DataObjectsCoreRebuilder.begin_rebuild
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
      sorted_by_default.should_not == sorted_by_rating
      previous_rating = 50000
      sorted_by_rating.each do |d|
        d.data_rating.should <= previous_rating
        previous_rating = d.data_rating
      end
      
    end

    it 'should sort media by newest' do
      media_do_index
      sorted_by_status = assigns[:media]
      sorted_by_status.first(10).should_not == @newest_media

      get :index, :taxon_id => @taxon_concept.id, :sort_by => 'newest'
      sorted_by_newest = assigns[:media]
      sorted_by_newest.should_not == sorted_by_status
      previous_date = 100.days.ago
      sorted_by_newest.reverse.each do |d|
        d.created_at.should >= previous_date
        previous_date = d.created_at
      end
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

    it 'should filter by vetted status and visibility'

    it 'should instantiate an assistive header' do
      media_do_index
      assigns[:assistive_section_header].should be_a(String)
    end
  end

  describe 'PUT set_as_exemplar' do
    it 'should not allow non-curators to set exemplar images' do
      @taxon_concept.taxon_concept_exemplar_image.should be_nil
      exemplar_image = @taxon_concept.images_from_solr.first
      expect{ put :set_as_exemplar, :taxon_id => @taxon_concept.id, :taxon_concept_exemplar_image => { :data_object_id => exemplar_image.id } }.to raise_error(EOL::Exceptions::SecurityViolation)
    end
    
    it 'should set an image as exemplar' do
      session[:user_id] = build_curator(@taxon_concept).id
      @taxon_concept.taxon_concept_exemplar_image.should be_nil
      exemplar_image = @taxon_concept.images_from_solr.first
      put :set_as_exemplar, :taxon_id => @taxon_concept.id, :taxon_concept_exemplar_image => { :data_object_id => exemplar_image.id }
      @taxon_concept.reload
      @taxon_concept.taxon_concept_exemplar_image.data_object_id.should == exemplar_image.id
      expect(response).to redirect_to(taxon_media_url(@taxon_concept))
    end
  end
end
