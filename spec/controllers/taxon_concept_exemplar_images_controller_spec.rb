require File.dirname(__FILE__) + '/../spec_helper'

describe TaxonConceptExemplarImagesController do

  before(:all) do
    truncate_all_tables
    load_scenario_with_caching :media_heavy
    @data = EOL::TestInfo.load('media_heavy')
    @taxon_concept = @data[:taxon_concept]
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
