require File.dirname(__FILE__) + '/../spec_helper'

# Surprisingly simple. ...That's because most of the work is (still) being done by TaxonConcept (which is really just calling Solr in
# complex ways).  :\
describe TaxonMedia do

  before(:all) do
    load_foundation_cache
    @taxon_concept = TaxonConcept.gen # Doesn't need to be anything fancy, here.
    @entry = HierarchyEntry.gen(taxon_concept: @taxon_concept)
    @user = User.gen
  end

  def build_media
    @media = TaxonMedia.new(@taxon_concept, @user)
  end

  it 'should get applied ratings from the specified user' do
    @user.should_receive(:rating_for_object_guids).and_return('hi')
    build_media
    @media.applied_ratings.should == 'hi'
  end

  it 'should get empty ratings from an anonymous user' do
    TaxonMedia.new(@taxon_concept, EOL::AnonymousUser.new('en')).applied_ratings.should == {}
  end

  it "should know if it's empty" # This is not simple to test; juice wasn't worth the squeeze and I didn't want to keep bad code. :\

  it 'should have an array of media to pass to will_paginate' do
    a = [DataObject.gen].paginate
    # NOTE - data_objects_from_solr is called in other places (for example, to get the exemplar image), but we don't care:
    @taxon_concept.should_receive(:data_objects_from_solr).at_least(1).times.and_return a
    build_media
    @media.paginated.should == a
  end

  it 'should implement #each_with_index over the media' do
    array = [DataObject.gen, DataObject.gen, DataObject.gen].paginate
    # NOTE - data_objects_from_solr is called in other places (for example, to get the exemplar image), but we don't care:
    @taxon_concept.should_receive(:data_objects_from_solr).at_least(1).times.and_return array
    build_media
    @media.each_with_index do |foo, bar|
      foo.should == array[bar]
    end
  end

  it 'should be a TaxonUserClassificationFilter ... most of its methods are implemented (and speced) there' do
    build_media
    @media.should be_a(TaxonUserClassificationFilter)
  end

  # Ouch. But, really, we *do* want to ensure we get all the arguments right, here. Still, TODO, this would be really nice to... improve.
  # Also, TODO, this is not exhaustive.  :\  We should pass in various arguments and see these change.
  it 'should pass arguments to taxon concept for getting media' do
    array = [DataObject.gen].paginate
    @taxon_concept.should_receive(:data_objects_from_solr).with(
      ignore_translations: true,
      return_hierarchically_aggregated_objects: true,
      page: 1,
      per_page: TaxonMedia::IMAGES_PER_PAGE,
      sort_by: 'status',
      data_type_ids: DataType.image_type_ids + DataType.video_type_ids + DataType.sound_type_ids,
      vetted_types: ['trusted', 'unreviewed'],
      visibility_types: ['visible'],
      # NOTE - as noted in the class itself, I don't understand why we need this with skip_preload true.
      preload_select: { data_objects: [ :id, :guid, :language_id, :data_type_id, :created_at, :mime_type_id, :object_title,
                                                :object_cache_url, :object_url, :data_rating, :thumbnail_cache_url, :data_subtype_id,
                                                :published ] }
    ).ordered.and_return array
    # This second call is made in order to get a count of all media. I'm not sure this is what was intended.  # TODO
    @taxon_concept.stub(:data_objects_from_solr).with(
      per_page: 1,
      sort_by: 'status',
      data_type_ids: DataType.image_type_ids,
      vetted_types: ['trusted', 'unreviewed'],
      visibility_types: ['visible'],
      published: true,
      return_hierarchically_aggregated_objects: true).ordered.and_return array

    # NOTE - this fails in the full test suite, occassionally.  Not sure why.  You might wanna check on that.
    build_media
    @media.paginated.should == array
  end

end
