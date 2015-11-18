require "spec_helper"

describe 'Structured Data Factories' do

  before(:all) do
    load_foundation_cache
    drop_all_virtuoso_graphs
    @taxon_concept = TaxonConcept.gen
    @resource = Resource.gen
  end

  describe 'Measurements' do
    before(:all) do
      @default_options = { resource: @resource, subject: @taxon_concept }
    end

    it 'should create the instance' do
      s = DataMeasurement.new(@default_options.merge(predicate: "eol:weight", object: "14"))
      s.subject.should == @taxon_concept
      s.predicate.should == "eol:weight"
      s.object.should == "14"
    end

    it 'should create a turle form' do
      s = DataMeasurement.new(@default_options.merge(predicate: "eol:weight", object: "14"))
      s.turtle.should include("a <#{DataMeasurement::CLASS_URI}>")
      s.turtle.should include('dwc:taxonID ')
      s.turtle.should include('dwc:measurementType ' + EOL::Sparql.enclose_value('eol:weight'))
      s.turtle.should include('dwc:measurementValue ' + EOL::Sparql.enclose_value('14'))
    end

    it 'should be able to interact with the triplestore' do
      s = DataMeasurement.new(@default_options.merge(predicate: "eol:weight", object: "14"))
      EOL::Sparql.count_triples_in_graph(s.graph_name).should == 0
      EOL::Sparql.count_triples_in_graph(s.entry_to_taxon_graph_name).should == 0
      s.add_to_triplestore
      EOL::Sparql.count_triples_in_graph(s.graph_name).should == 7
      EOL::Sparql.count_triples_in_graph(s.entry_to_taxon_graph_name).should == 1
      s.remove_from_triplestore
      EOL::Sparql.count_triples_in_graph(s.graph_name).should == 0
      EOL::Sparql.count_triples_in_graph(s.entry_to_taxon_graph_name).should == 0
      s.update_triplestore
      EOL::Sparql.count_triples_in_graph(s.graph_name).should == 7
      EOL::Sparql.count_triples_in_graph(s.entry_to_taxon_graph_name).should == 1
      s.update_triplestore
      EOL::Sparql.count_triples_in_graph(s.graph_name).should == 7
      EOL::Sparql.count_triples_in_graph(s.entry_to_taxon_graph_name).should == 1
      s.remove_from_triplestore
    end
  end

  describe 'Associations' do
    before(:all) do
      @target_taxon_concept = TaxonConcept.gen
      @default_options = { resource: @resource, subject: @taxon_concept, object: @target_taxon_concept }
    end

    it 'should create the instance' do
      a = DataAssociation.new(@default_options)
      a.subject.should == @taxon_concept
      a.object.should == @target_taxon_concept
    end

    it 'should create a turtle form' do
      a = DataAssociation.new(@default_options)
      a.turtle.should include('a <http://eol.org/schema/Association>')
      a.turtle.should include('dwc:taxonID ')
      a.turtle.should include('eol:targetOccurrenceID ')
    end

    it 'should be able to interact with the triplestore' do
      a = DataAssociation.new(@default_options)
      EOL::Sparql.count_triples_in_graph(a.graph_name).should == 0
      EOL::Sparql.count_triples_in_graph(a.entry_to_taxon_graph_name).should == 0
      a.add_to_triplestore
      EOL::Sparql.count_triples_in_graph(a.graph_name).should == 7
      EOL::Sparql.count_triples_in_graph(a.entry_to_taxon_graph_name).should == 2
      a.remove_from_triplestore
      EOL::Sparql.count_triples_in_graph(a.graph_name).should == 0
      EOL::Sparql.count_triples_in_graph(a.entry_to_taxon_graph_name).should == 0
      a.update_triplestore
      EOL::Sparql.count_triples_in_graph(a.graph_name).should == 7
      EOL::Sparql.count_triples_in_graph(a.entry_to_taxon_graph_name).should == 2
      a.update_triplestore
      EOL::Sparql.count_triples_in_graph(a.graph_name).should == 7
      EOL::Sparql.count_triples_in_graph(a.entry_to_taxon_graph_name).should == 2
      a.remove_from_triplestore
    end
  end

end
