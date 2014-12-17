require "spec_helper"

describe DataSearchController do

  before(:all) do
    load_foundation_cache
    drop_all_virtuoso_graphs
    @user = User.gen
    @user.grant_permission(:see_data)
    @taxon_concept = build_taxon_concept
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
end