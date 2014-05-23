require File.dirname(__FILE__) + '/../../../spec_helper'

describe EOL::Sparql::Client do
  before(:all) do
    load_foundation_cache
    @taxon_concept = build_taxon_concept
    @client = EOL::Sparql::Client.new
  end

  describe 'clear_uri_caches' do
    it 'removes some data cached from Virtuoso' do
      expect(Rails.cache).to receive(:delete).with('eol/sparql/client/all_measurement_type_uris')
      expect(Rails.cache).to receive(:delete).with('eol/sparql/client/all_measurement_type_known_uris')
      EOL::Sparql::Client.clear_uri_caches
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
