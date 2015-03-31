require "spec_helper"

describe DataSearchController do

  before(:all) do
    load_foundation_cache
    drop_all_virtuoso_graphs
    @user = User.gen
    @user.grant_permission(:see_data)
    @taxon_concept = build_taxon_concept(:comments => [], :bhl => [], :toc => [], :images => [], :sounds => [], :youtube => [], :flash => [])
    @resource = Resource.gen
    @default_data_options = { subject: @taxon_concept, resource: @resource }
  end

  before(:each) do
    session[:user_id] = @user.id
    DataSearchLog.destroy_all
  end

  describe 'Logging' do

    it 'should not generate data search logs when there is no attribute' do
      get :index
      expect(DataSearchLog.count).to eq(0)
    end

    it 'should generate data search logs when there is an attribute specified' do
      get :index, attribute: 'anything'
      expect(DataSearchLog.count).to eq(1)
    end

    it 'should log when the specifed clade was searchable' do
      expect(TaxonData).to receive(:is_clade_searchable?).at_least(1).times.with(@taxon_concept).and_return(true)
      get :index, attribute: 'anything', taxon_concept_id: @taxon_concept.id
      expect(DataSearchLog.last.clade_was_ignored).to eq(false)
    end

    it 'should log when the specifed clade was not searchable' do
      expect(TaxonData).to receive(:is_clade_searchable?).at_least(1).times.with(@taxon_concept).and_return(false)
      get :index, attribute: 'anything', taxon_concept_id: @taxon_concept.id
      expect(DataSearchLog.last.clade_was_ignored).to eq(true)
    end

    it 'should generate data search logs when there is an attribute specified' do
      get :index, attribute: 'ATTRIBUTE', q: 'AQUERY', min: 100, max: 1000, unit: 'UNIT',
        sort: 'asc', taxon_concept_id: @taxon_concept.id
      expect(DataSearchLog.last.uri).to eq('ATTRIBUTE')
      expect(DataSearchLog.last.q).to eq('AQUERY')
      expect(DataSearchLog.last.from).to eq(100)
      expect(DataSearchLog.last.to).to eq(1000)
      expect(DataSearchLog.last.unit_uri).to eq('UNIT')
      expect(DataSearchLog.last.sort).to eq('asc')
      expect(DataSearchLog.last.number_of_results).to eq(0)
      expect(DataSearchLog.last.time_in_seconds).not_to eq(nil)
      expect(DataSearchLog.last.time_in_seconds).to be_a_kind_of(Float)
      expect(DataSearchLog.last.taxon_concept_id).to eq(@taxon_concept.id)
      expect(DataSearchLog.last.language_id).to eq(@user.language_id)
    end

    it 'should list the number of results' do
      get :index, attribute: 'http://eol.org/weight'
      expect(DataSearchLog.last.number_of_results).to eq(0)  # starts with no results
      DataMeasurement.new(@default_data_options.merge(predicate: 'http://eol.org/weight', object: '32')).update_triplestore
      get :index, attribute: 'http://eol.org/weight'
      expect(DataSearchLog.last.number_of_results).to eq(1)  # now have 1 result
      DataMeasurement.new(@default_data_options.merge(predicate: 'http://eol.org/weight', object: '23423')).update_triplestore
      get :index, attribute: 'http://eol.org/weight'
      expect(DataSearchLog.last.number_of_results).to eq(2)  # now have 2 results
      drop_all_virtuoso_graphs
      get :index, attribute: 'http://eol.org/weight'
      expect(DataSearchLog.last.number_of_results).to eq(0)  # tiplestore truncated, back to 0 results
    end
    
    describe "equivalent attributes and values" do
      before :all do
        Language.create_english
        #attributes
        k1 = KnownUri.gen
        k1.update_attributes(uri: 'http://eol.org/eye_color') 
        TranslatedKnownUri.create(known_uri_id: k1.id, name: "eye color", language_id: Language.first.id)
        k2 = KnownUri.gen
        @k2_id = k2.id
        k2.update_attributes(uri: 'http://eol.org/color')
        TranslatedKnownUri.create(known_uri_id: k2.id, name: "color", language_id: Language.first.id)
        KnownUriRelationship.create(from_known_uri_id: k1.id,to_known_uri_id: k2.id, relationship_uri: 'http://www.w3.org/2002/07/owl#equivalentProperty')
        #values
        v1 = KnownUri.gen
        v1.update_attributes(uri: 'http://eol.org/violet')
        TranslatedKnownUri.create(known_uri_id: v1.id, name: "violet", language_id: Language.first.id)
        v2 = KnownUri.gen
        @v2_id = v2.id
        v2.update_attributes(uri: 'http://eol.org/purple')
        TranslatedKnownUri.create(known_uri_id: v2.id, name: "purple", language_id: Language.first.id)
        KnownUriRelationship.create(from_known_uri_id: v1.id,to_known_uri_id: v2.id, relationship_uri: 'http://www.w3.org/2002/07/owl#equivalentProperty')
        DataMeasurement.new(@default_data_options.merge(predicate: 'http://eol.org/eye_color', object: 'http://eol.org/purple')).update_triplestore
        DataMeasurement.new(@default_data_options.merge(predicate: 'http://eol.org/eye_color', object: 'http://eol.org/violet')).update_triplestore
        DataMeasurement.new(@default_data_options.merge(predicate: 'http://eol.org/color', object: 'http://eol.org/violet')).update_triplestore
      end
      
      it 'should search with equivalent attributes' do
        get :index, attribute: 'http://eol.org/eye_color', required_equivalent_attributes: ["#{@k2_id}"]
        expect(DataSearchLog.last.number_of_results).to eq(3)
      end
      
      it 'should search with equivalent values' do
        get :index, attribute: 'http://eol.org/eye_color', q: "http://eol.org/violet", required_equivalent_values: ["#{@v2_id}"]
        expect(DataSearchLog.last.number_of_results).to eq(2)
      end
    end
    
    describe "taxon autocomplete" do
      
      before(:all) do
        @taxon_name = TaxonConceptName.first
        @name = Name.find(@taxon_name.name_id)
        @taxon = TaxonConcept.find(@taxon_name.taxon_concept_id)
        KnownUri.gen(uri: "http://eol.org/weight")
        @size_uri = KnownUri.gen(uri: "http://eol.org/size")
        EOL::Solr::SiteSearchCoreRebuilder.begin_rebuild
        DataMeasurement.new(subject: @taxon, resource: @resource, predicate: 'http://eol.org/weight', object: '32').update_triplestore
        DataMeasurement.new(subject: @taxon, resource: @resource, predicate: 'http://eol.org/length', object: '40').update_triplestore
      end
      
      it "should select the first taxon if there is many results for taxon name" do
        get :index, attribute: 'http://eol.org/weight', taxon_name: "#{@name.string}"
        expect(DataSearchLog.last.number_of_results).to eq(1)
        expect(DataSearchLog.last.taxon_concept_id).to eq(@taxon.id)
      end
      
      describe "TraitBank search options" do
        
        it "should not display diused uris in traitbank search options" do # disused attributes
          get :index
          expect(response.body).not_to have_selector('option', value: "http://eol.org/size")
        end
        
        it "should not display uris that are not in known uris in traitbank search options" do  # attributes are not in known uris
          get :index
          expect(response.body).not_to have_selector('option', value: "http://eol.org/length")
        end
        
      end      
    end    

  end
  
  describe "search" do
    before :all do
      DataMeasurement.new(@default_data_options.merge(predicate: 'http://eol.org/mass', object: '10')).update_triplestore
      DataMeasurement.new(@default_data_options.merge(predicate: 'http://eol.org/mass', object: '100')).update_triplestore
    end
     it 'should search with min and max values' do
      get :index, attribute: 'http://eol.org/mass', min: 10, max: 100
      expect(DataSearchLog.last.number_of_results).to eq(2)
    end
    
    it 'should fix min and max' do
      get :index, attribute: 'http://eol.org/mass', min: 100, max: 10
      expect(DataSearchLog.last.number_of_results).to eq(2)
    end
  end
end