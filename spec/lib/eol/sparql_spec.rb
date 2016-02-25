require File.dirname(__FILE__) + '/../../spec_helper'

describe EOL::Sparql do

  before(:all) do
    truncate_all_tables
    populate_tables(:visibilities, :uri_types)
    # UriType.create_enumerated
  end

  before(:each) do
    KnownUri.destroy_all
    TranslatedKnownUri.destroy_all
    KnownUriRelationship.destroy_all
    KnownUri.gen_if_not_exists(uri: Rails.configuration.uri_measurement_unit, name: 'unit_of_measure')
    # clear the cached version of KnownUri.unit_of_measure before each spec
    KnownUri.remove_class_variable('@@unit_of_measure') if KnownUri.class_variable_defined?('@@unit_of_measure')
  end

  it 'should create a connection' do
    EOL::Sparql.connection.class.should == EOL::Sparql::VirtuosoClient
  end

  it 'should to_underscore' do
    EOL::Sparql.to_underscore('Some thing').should == 'some_thing'
    EOL::Sparql.to_underscore('SomeThing').should == 'something'
    EOL::Sparql.to_underscore('Some  Thing').should == 'some_thing'
    EOL::Sparql.to_underscore(' 	  Some  Thing  ').should == 'some_thing'
  end

  it 'should uri_to_readable_label' do
    EOL::Sparql.uri_to_readable_label('http://example.com/grams').should == 'Grams'
    EOL::Sparql.uri_to_readable_label('http://example.com/one_a_day').should == 'One A Day'
    EOL::Sparql.uri_to_readable_label('http://example.com/oneADay').should == 'One A Day'
    EOL::Sparql.uri_to_readable_label('http://example.com/59ADay').should == '59 A Day'
    EOL::Sparql.uri_to_readable_label('http://example.com#some-thing').should == 'Some Thing'
    EOL::Sparql.uri_to_readable_label('http://example.com#just-1-more').should == 'Just 1 More'
  end

  it 'should explicit_measurement_uri_components' do
    # when there is a unit in the metadata, there must be a matching KnownURI
    EOL::Sparql.explicit_measurement_uri_components({ Rails.configuration.uri_measurement_unit =>
      'http://example.com/grams' }).should == nil
    grams = KnownUri.gen_if_not_exists(uri: 'http://example.com/grams', name: 'grams')
    KnownUri.unit_of_measure.add_value(grams)
    data_value = EOL::Sparql.explicit_measurement_uri_components(grams)
    expect(data_value.uri).to eq("http://example.com/grams")
    expect(data_value.label).to eq("grams")
    expect(data_value.definition).to be_nil
  end

  it 'should implicit_measurement_uri_components' do
    length = KnownUri.gen_if_not_exists(uri: 'http://example.com/length', name: 'length')
    EOL::Sparql.implicit_measurement_uri_components(length).should == nil
    meters = KnownUri.gen_if_not_exists(uri: 'http://example.com/meters', name: 'meters', uri_type: UriType.value)
    EOL::Sparql.implicit_measurement_uri_components(length).should == nil
    KnownUri.unit_of_measure.add_value(meters)
    length.add_implied_unit(meters)
    length.reload
    data_value = EOL::Sparql.implicit_measurement_uri_components(length)
    expect(data_value.uri).to eq("http://example.com/meters")
    expect(data_value.label).to eq("meters")
    expect(data_value.definition).to be_nil
  end

  it 'should implied_unit_of_measure_for_uri' do
    KnownUri.gen_if_not_exists(uri: Rails.configuration.uri_measurement_unit, name: 'unit_of_measure')
    height = KnownUri.gen_if_not_exists(uri: 'http://example.com/height', name: 'length')
    EOL::Sparql.implied_unit_of_measure_for_uri(height).should == nil
    meters = KnownUri.gen_if_not_exists(uri: 'http://example.com/meters', name: 'meters', uri_type: UriType.value)
    KnownUri.unit_of_measure.add_value(meters)
    height.add_implied_unit(meters)
    height.reload
    EOL::Sparql.implied_unit_of_measure_for_uri(height).should == meters
    random_known_uri = KnownUri.gen_if_not_exists(uri: 'http://example.com/width', name: 'width')
    EOL::Sparql.implied_unit_of_measure_for_uri(random_known_uri).should == nil
  end

  it 'should is_known_unit_of_measure_uri?' do
    EOL::Sparql.is_known_unit_of_measure_uri?('http://example.com/gallons').should == nil
    gallons = KnownUri.gen_if_not_exists(uri: 'http://example.com/gallons', name: 'gallons', uri_type: UriType.value)
    KnownUri.unit_of_measure.add_value(gallons)
    EOL::Sparql.is_known_unit_of_measure_uri?(gallons).should == true
  end

  it 'should uri_components' do
    data_value = EOL::Sparql.uri_components('http://example.com/potatoes')
    expect(data_value.uri).to eq("http://example.com/potatoes")
    expect(data_value.label).to eq("Potatoes")
    known = KnownUri.gen_if_not_exists(uri: 'http://example.com/potatoes', name: 'Potatoes')
    data_value = EOL::Sparql.uri_components(known)
    expect(data_value.uri).to eq("http://example.com/potatoes")
    expect(data_value.label).to eq("Potatoes")
    expect(data_value.definition).to be_nil
    data_value = EOL::Sparql.uri_components('nonsense')
    expect(data_value.uri).to eq("nonsense")
    expect(data_value.label).to eq("nonsense")
  end

  it 'should is_uri' do
    EOL::Sparql.is_uri?("http://eol.org").should == true
    EOL::Sparql.is_uri?("http://a").should == true
    EOL::Sparql.is_uri?("http://").should == false
    EOL::Sparql.is_uri?("<http://eol.org>").should == true
    EOL::Sparql.is_uri?("<http://a>").should == true
    EOL::Sparql.is_uri?("<http://>").should == false
    EOL::Sparql.is_uri?("ns:ok").should == true
    EOL::Sparql.is_uri?("ns:some_attri-bute91").should == true
    EOL::Sparql.is_uri?("ns:ATest").should == true
    EOL::Sparql.is_uri?("ns:").should == false
    EOL::Sparql.is_uri?("ns:asd asdf").should == false
    EOL::Sparql.is_uri?("ns:att[r]").should == false
  end

  it 'should enclose_value' do
    EOL::Sparql.enclose_value("http://eol.org").should == "<http://eol.org>"
    EOL::Sparql.enclose_value("<http://eol.org>").should == "<http://eol.org>"
    EOL::Sparql.enclose_value("this is a test").should == "\"this is a test\""
    EOL::Sparql.enclose_value("http://eol. org").should == "\"http://eol. org\""
    EOL::Sparql.enclose_value("eol:term").should == "eol:term"
  end

  it 'should expand_namespaces' do
    EOL::Sparql.expand_namespaces("eol:something").should == Rails.configuration.uri_prefix + "something"
    EOL::Sparql.expand_namespaces("EOL:something").should == Rails.configuration.uri_prefix + "something"
    EOL::Sparql.expand_namespaces("dwc:something").should == "http://rs.tdwg.org/dwc/terms/something"
    EOL::Sparql.expand_namespaces("DWC:SOMETHING").should == "http://rs.tdwg.org/dwc/terms/SOMETHING"
    EOL::Sparql.expand_namespaces("EoLTeRmS:something").should == Rails.configuration.uri_term_prefix + "something"
    EOL::Sparql.expand_namespaces("eolterms:something").should == Rails.configuration.uri_term_prefix + "something"
    EOL::Sparql.expand_namespaces(Rails.configuration.uri_term_prefix + "something").should == Rails.configuration.uri_term_prefix + "something"
    EOL::Sparql.expand_namespaces("<#{Rails.configuration.uri_term_prefix}something>").should == Rails.configuration.uri_term_prefix + "something"
    EOL::Sparql.expand_namespaces("this is a test").should == "this is a test"
    EOL::Sparql.expand_namespaces("unknown_namespace:something").should == false
    EOL::Sparql.expand_namespaces("eol::test").should == "eol::test"
  end

  it 'should convert' do
    EOL::Sparql.convert("test").should == "test"
    EOL::Sparql.convert("Test").should == "Test"
    EOL::Sparql.convert("Test & test").should == "Test &amp; test"
    EOL::Sparql.convert("Test & <test>").should == "Test &amp; &lt;test&gt;"
    EOL::Sparql.convert("Test\n \\& \r<tes't>").should == "Test &amp; &lt;tes&apos;t&gt;"
    EOL::Sparql.convert("Test \"test\"").should == "Test &quot;test&quot;"
  end

  # moved the feature ro tramea!
  # it 'should count_triples_in_graph' do
    # drop_all_virtuoso_graphs
    # EOL::Sparql.count_triples_in_graph("fictional_graph").should == 0
    # EOL::Sparql.count_triples_in_graph(UserAddedData::GRAPH_NAME).should == 0
    # UserAddedData.gen
    # EOL::Sparql.count_triples_in_graph(UserAddedData::GRAPH_NAME).should == 5
  # end
end

