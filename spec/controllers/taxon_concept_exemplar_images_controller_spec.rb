require "spec_helper"

describe TaxonConceptExemplarImagesController do

  before(:all) do
    load_foundation_cache
    images = []
    10.times { images << { :data_rating => 1 + rand(5), :source_url => 'http://photosynth.net/identifying/by/string/is/bad/change/me' } }
    10.times { images << { :data_rating => 1 + rand(5), :vetted => Vetted.unknown } }
    10.times { images << { :data_rating => 1 + rand(5), :vetted => Vetted.untrusted } }
    10.times { images << { :data_rating => 1 + rand(5), :vetted => Vetted.inappropriate } }
    @taxon_concept = build_taxon_concept(:canonical_form => 'Copious picturesqus', :common_names => [ 'Snappy' ],
                                             :images => images, comments: [])
    EOL::Solr::DataObjectsCoreRebuilder.begin_rebuild
  end

  describe 'PUT set_as_exemplar' do
    it 'should not allow non-curators to set exemplar images' do
      TopConceptImage.delete_all(:taxon_concept_id => @taxon_concept.id)
      exemplar_image = @taxon_concept.images_from_solr.first
      expect{ put :create, :taxon_concept_exemplar_image => { :taxon_concept_id => @taxon_concept.id, :data_object_id => exemplar_image.id } }.to raise_error(EOL::Exceptions::SecurityViolation)
    end
    
    it 'should set an image as exemplar' do
      session[:user_id] = build_curator(@taxon_concept).id
      @taxon_concept.taxon_concept_exemplar_image.should be_nil
      exemplar_image = @taxon_concept.images_from_solr.first
      put :create, :taxon_concept_exemplar_image => { :taxon_concept_id => @taxon_concept.id, :data_object_id => exemplar_image.id }
      @taxon_concept.reload
      @taxon_concept.taxon_concept_exemplar_image.data_object_id.should == exemplar_image.id
      expect(response).to redirect_to(taxon_media_url(@taxon_concept))
    end
  end
end
