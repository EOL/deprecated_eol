require File.dirname(__FILE__) + '/../../../spec_helper'

describe EOL::Sparql::Client do
  before(:all) do
    load_foundation_cache
    @taxon_concept = build_taxon_concept(:comments => [], :toc =>[], :bhl => [], :images => [], :sounds => [], :youtube => [], :flash => [])
    @client = EOL::Sparql::Client.new
  end

  describe "#cache_key" do
    it "uses underscores to cache names" do
      expect(EOL::Sparql::Client.cache_key("foo")).to eq "eol_sparql_client_foo"
    end
  end

  describe "#clade_cache_key" do
    it "adds id to name" do
      expect(EOL::Sparql::Client.clade_cache_key(123)).to eq(
        EOL::Sparql::Client.cache_key("all_measurement_type_known_uris_for_clade_123")
      )
    end
  end

  describe '#clear_uri_caches' do

    let(:caches) {
      { all_measurement_type_uris: "har",
        all_measurement_type_known_uris: "hee",
        cached_taxon_1: 100,
        cached_taxon_2: 200,
        cached_taxon_3: 300
      }
    }

    before do
      caches.each do |key, val|
        Rails.cache.write(
          EOL::Sparql::Client.cache_key(key), val)
      end
      Rails.cache.write(
        EOL::Sparql::Client.clade_cache_key(caches[:cached_taxon_1]), "foo")
      Rails.cache.write(
        EOL::Sparql::Client.clade_cache_key(caches[:cached_taxon_2]), "bar")
      Rails.cache.write(
        EOL::Sparql::Client.clade_cache_key(caches[:cached_taxon_3]), "baz")
    end

    it 'removes some data cached from Virtuoso' do
      EOL::Sparql::Client.clear_uri_caches
      caches.keys.each do |key|
        expect(Rails.cache.exist?(EOL::Sparql::Client.cache_key(key))).to be false
      end
    end
  end

  describe '#initialize' do
    it 'creates an instance' do
      expect(@client).to be_a(EOL::Sparql::Client)
    end
  end

  describe '#insert_data' do
    it 'requires insert_data to be implemented in a child class' do
      expect{ @client.insert_data }.to raise_error(NotImplementedError)
    end
  end

  describe '#delete_data' do
    it 'deletes data when there is a graph_name and data' do
      expect(@client).to receive(:update).with('DELETE DATA FROM <TheGraph> { TheData }')
      @client.delete_data(graph_name: 'TheGraph', data: 'TheData')
    end

    it 'does not delete data when there is no graph_name' do
      expect(@client).to_not receive(:update)
      @client.delete_data(data: 'TheData')
    end

    it 'does not delete data when there is no data' do
      expect(@client).to_not receive(:update)
      @client.delete_data(graph_name: 'TheGraph')
    end
  end

end
