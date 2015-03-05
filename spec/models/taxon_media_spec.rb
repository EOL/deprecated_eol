require "spec_helper"

# Surprisingly simple. ...That's because most of the work is (still) being done by TaxonConcept (which is really
# just calling Solr in complex ways).  :\
describe TaxonMedia do

  before(:all) do
    Language.create_english
    populate_tables(:data_types, :licenses, :mime_types, :visibilities)
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

  # TODO, this is not exhaustive.  :\  We should pass in various arguments and
  # see these change. ...Or perhaps we should just have really good tests for
  # data_objects_from_solr
  it "calls TaxonConcept#data_objects_from_solr twice" do
    array = [DataObject.gen].paginate
    allow(taxon_concept).to receive(:data_objects_from_solr).exactly(2).times.
      and_return(array)
    expect(media.paginated).to eq(array)
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
