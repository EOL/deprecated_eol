require "spec_helper"

# Surprisingly simple. ...That's because most of the work is (still) being done by TaxonConcept (which is really
# just calling Solr in complex ways).  :\
describe TaxonMedia do

  before(:all) do
    DataType.create_enumerated
    License.create_enumerated
    Language.create_english
    MimeType.create_enumerated
  end

  let(:taxon_concept) { build_stubbed(TaxonConcept) }
  let(:entry) { build_stubbed(HierarchyEntry, taxon_concept: taxon_concept) }
  let(:user) { build_stubbed(User) }
  let(:media) { TaxonMedia.new(taxon_concept, user) }

  it 'has a paginated array of data objects' do
    array = [DataObject.gen].paginate 
    allow(taxon_concept).to receive(:data_objects_from_solr) { array }
    expect(media.paginated).to eq(array)
    expect(taxon_concept).to have_received(:data_objects_from_solr).at_least(1).times
  end

  describe '#each_with_index' do

    it 'iterates over data objects' do
      array = build_list(DataObject, 3).paginate
      allow(taxon_concept).to receive(:data_objects_from_solr) { array }
      # Best image is loaded with .fetch:
      allow(DataObject).to receive(:fetch) { array.first }
      media.each_with_index do |object, index|
        expect(object).to eq(array[index])
      end
    end

  end
  
  # NOTE - this is important mostly because a lot of the methods we'll end up calling on it in the controller/view
  # are actually inherited from this class (which should be tested on its own, of course).
  it 'inherits from TaxonUserClassificationFilter' do
    expect(media).to be_a(TaxonUserClassificationFilter)
  end

  # Ouch. But, really, we *do* want to ensure we get all the arguments right, here. Still, TODO, this would be
  # really nice to... improve.  Also, TODO, this is not exhaustive.  :\  We should pass in various arguments and see
  # these change.
  it 'passes an evil array of arguments to TaxonConcept#data_objects_from_solr' do
    array = [DataObject.gen].paginate
    allow(taxon_concept).to receive(:data_objects_from_solr).with(
      ignore_translations: true,
      return_hierarchically_aggregated_objects: true,
      page: 1,
      per_page: TaxonMedia::IMAGES_PER_PAGE,
      sort_by: 'status',
      data_type_ids: DataType.image_type_ids + DataType.video_type_ids + DataType.sound_type_ids,
      vetted_types: ['trusted', 'unreviewed'],
      visibility_types: ['visible'],
      # NOTE - as noted in the class itself, I don't understand why we need this with skip_preload true.
      preload_select: { data_objects: [ :id, :guid, :language_id, :data_type_id, :created_at, :mime_type_id,
        :object_title, :object_cache_url, :object_url, :data_rating, :thumbnail_cache_url, :data_subtype_id,
        :published ] }
    ) { array }
    # This second call is made in order to get a count of all media.
    allow(taxon_concept).to receive(:data_objects_from_solr).with(
      per_page: 1,
      sort_by: 'status',
      data_type_ids: DataType.image_type_ids,
      vetted_types: ['trusted', 'unreviewed'],
      visibility_types: ['visible'],
      published: true,
      return_hierarchically_aggregated_objects: true) { array }
    media.paginated.should == array
  end

  # TODO - really, a lot of the above tests could be done with stubbing rather than reading the DB. Fix.
  context 'stubbed' do 

    describe '#empty?' do

      context 'with no media' do

        let(:taxon_media) do
          allow(taxon_concept).to receive(:data_objects_from_solr) { [].paginate }
          TaxonMedia.new(taxon_concept, user)
        end

        it 'knows it is empty' do
          expect(taxon_media.empty?).to be_true
        end

      end

      context 'with media' do

        let(:taxon_media) do
          allow(taxon_concept).to receive(:data_objects_from_solr) { [].paginate }
          TaxonMedia.new(taxon_concept, user)
        end

      end

    end

  end

end
