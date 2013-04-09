require File.dirname(__FILE__) + '/../spec_helper'

describe UserAddedData do

  before(:all) do
    @user = User.gen
    @tc   = TaxonConcept.gen
    @valid_args = {
      subject:   @tc,
      predicate: "http://somethinguseful.com/fake_ontology",
      object:    "foo",
      user:      @user
    }
    @uad = UserAddedData.gen
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

end
