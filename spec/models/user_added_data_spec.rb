require "spec_helper"

describe UserAddedData do

  # TODO - this spec runs really slowly. Figure out why and fix it.

  before(:all) do
    @test_user = User.gen
    @test_subject_concept = TaxonConcept.gen
    @test_predicate = 'http://somethinguseful.com/fake_ontology'
    @test_object = 'foo'
    @valid_args = {
      subject:      @test_subject_concept,
      predicate:    @test_predicate,
      object:       @test_object,
      user:         @test_user
    }
    @uad = UserAddedData.gen
  end

  describe '#turtle' do

    let(:predicate) { 'predicated upon' }
    let(:object) { 'of my affection' }
    let(:user_added_data) { build_stubbed(UserAddedData) }
    let(:user_added_data_metadata) do
      UserAddedDataMetadata.new(predicate: predicate,
                                object: object,
                                user_added_data: user_added_data)
    end
    subject { user_added_data_metadata.turtle }

    before do
      # Easier than building a valid uri on the model:
      allow(user_added_data).to receive(:uri) { 'this uri' }
      allow(EOL::Sparql).to receive(:enclose_value) { |arg| "#{arg} enclosed" }
    end
    
    it 'makes a tag of the uri' do
      expect(subject).to match(/<#{user_added_data.uri}>/)
    end

    it 'encloses the predicate' do
      expect(subject).to match(/#{predicate} enclosed/)
      expect(EOL::Sparql).to have_received(:enclose_value).with(predicate)
    end

    it 'encloses the object' do
      expect(subject).to match(/#{object} enclosed/)
      expect(EOL::Sparql).to have_received(:enclose_value).with(object)
    end

  end

  it 'should create a valid user added data instance' do
    uad = UserAddedData.new(@valid_args)
    uad.should be_valid
    uad.subject.should == @test_subject_concept
    uad.subject_type.should == 'TaxonConcept'
    uad.subject_id.should == @test_subject_concept.id
    uad.predicate.should == @test_predicate
    uad.object.should == @test_object
    uad.user.should == @test_user
  end

  it 'should be invalid if the subject_type is not present' do
    UserAddedData.new(@valid_args.merge(subject_type: nil)).should_not be_valid
  end

  it 'should be invalid if the subject_id is not present' do
    UserAddedData.new(@valid_args.merge(subject_id: nil)).should_not be_valid
  end

  it 'should be invalid if the predicate is not a uri' do
    UserAddedData.new(@valid_args.merge(predicate: "not a URI")).should_not be_valid
  end

  it 'should be invalid if the predicate is not in a known namespace' do
    UserAddedData.new(@valid_args.merge(predicate: "badns:something")).should_not be_valid
  end

  it 'should be invalid if the object is not in a known namespace' do
    UserAddedData.new(@valid_args.merge(object: "badns:something")).should_not be_valid
  end

  it 'should dereference namespaces' do
    uad = UserAddedData.new(@valid_args.merge(object: "dwc:something"))
    uad.should be_valid
    uad.object.should == "#{EOL::Sparql::NAMESPACES['dwc']}something"
  end

  # NOTE - this does expect an array for the data...
  it '#add_to_triplestore should call SPARQL with its turtle in the proper namespace' do
    @uad.should_receive(:turtle).and_return('whatever')
    # NOTE - sparql is a private method.
    @uad.send(:sparql).should_receive(:insert_data).with(data: ['whatever'],
                                                         graph_name: UserAddedData::GRAPH_NAME).and_return(true)
    @uad.add_to_triplestore
  end

  # NOTE - this does NOT expect an array for the data...
  it '#remove_from_triplestore should call SPARQL with its turtle in the proper namespace' do
    # NOTE - sparql is a private method.
    @uad.send(:sparql).should_receive(:delete_uri).with(uri: @uad.uri,
                                                        graph_name: UserAddedData::GRAPH_NAME).and_return(true)
    @uad.remove_from_triplestore
  end

  it 'should add fields to triplestore' do
    drop_all_virtuoso_graphs
    user_added_data = UserAddedData.gen
    results = EOL::Sparql.connection.query("SELECT ?s ?p ?o FROM <" + UserAddedData::GRAPH_NAME + "> WHERE { ?s ?p ?o }")
    normalized_results = results.collect{ |r| [ r[:s].to_s, r[:p].to_s, r[:o].to_s ] }
    normalized_results.should include([ user_added_data.uri, 'http://www.w3.org/1999/02/22-rdf-syntax-ns#type',
      DataMeasurement::CLASS_URI])
    normalized_results.should include([ user_added_data.uri, 'http://rs.tdwg.org/dwc/terms/taxonConceptID',
      SparqlQuery::TAXON_PREFIX + user_added_data.subject.id.to_s ])
    normalized_results.should include([ user_added_data.uri, 'http://rs.tdwg.org/dwc/terms/measurementType', user_added_data.predicate ])
    normalized_results.should include([ user_added_data.uri, 'http://rs.tdwg.org/dwc/terms/measurementValue', user_added_data.object ])
    normalized_results.length.should == 5
  end

  it 'should remove fields from triplestore when deleted' do
    drop_all_virtuoso_graphs
    user_added_data = UserAddedData.gen
    EOL::Sparql.count_triples_in_graph(UserAddedData::GRAPH_NAME).should == 5
    user_added_data.update_attributes({ deleted_at: Time.now })
    EOL::Sparql.count_triples_in_graph(UserAddedData::GRAPH_NAME).should == 0
  end

  it 'should be able to drop the UserAddedData graph' do
    drop_all_virtuoso_graphs
    UserAddedData.gen
    EOL::Sparql.count_triples_in_graph(UserAddedData::GRAPH_NAME).should == 5
    UserAddedData.delete_graph
    EOL::Sparql.count_triples_in_graph(UserAddedData::GRAPH_NAME).should == 0
  end

  it 'should be able to interact with the triplestore' do
    drop_all_virtuoso_graphs
    d = UserAddedData.gen
    EOL::Sparql.count_triples_in_graph(UserAddedData::GRAPH_NAME).should == 5
    d.remove_from_triplestore
    EOL::Sparql.count_triples_in_graph(UserAddedData::GRAPH_NAME).should == 0
    d.update_triplestore
    EOL::Sparql.count_triples_in_graph(UserAddedData::GRAPH_NAME).should == 5
    d.update_triplestore
    EOL::Sparql.count_triples_in_graph(UserAddedData::GRAPH_NAME).should == 5
  end

  it 'should be able to recreate the UserAddedData graph' do
    drop_all_virtuoso_graphs
    UserAddedData.destroy_all
    UserAddedData.gen
    EOL::Sparql.count_triples_in_graph(UserAddedData::GRAPH_NAME).should == 5
    UserAddedData.delete_graph
    EOL::Sparql.count_triples_in_graph(UserAddedData::GRAPH_NAME).should == 0
    UserAddedData.recreate_triplestore_graph
    EOL::Sparql.count_triples_in_graph(UserAddedData::GRAPH_NAME).should == 5
  end

  it 'should create a DataPointURI' do
    d = UserAddedData.gen()
    d.data_point_uri.is_a?(DataPointUri).should be_true
    d.data_point_uri.uri.should == d.uri
    d.data_point_uri.taxon_concept_id.should == d.taxon_concept_id
    d.data_point_uri.class_type.should == 'MeasurementOrFact'
    d.data_point_uri.user_added_data_id.should == d.id
    d.data_point_uri.vetted_id.should == d.vetted_id
    d.data_point_uri.visibility_id.should == d.visibility_id
    d.data_point_uri.predicate.should == d.predicate
    d.data_point_uri.object.should == d.object
    d.data_point_uri.unit_of_measure.should == nil
  end

  it 'should update its DataPointURI' do
    d = UserAddedData.gen(object: 'hello')
    d.data_point_uri.class.should == DataPointUri
    d.data_point_uri.object.should == 'hello'
    d.object = 'goodbye'
    d.save
    d.data_point_uri.object.should == 'goodbye'
  end

end
