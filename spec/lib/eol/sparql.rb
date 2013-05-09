require File.dirname(__FILE__) + '/../../spec_helper'

describe EOL::Sparql do

  before(:all) do
    truncate_all_tables
  end

  it 'should create a connection' do
    EOL::Sparql.connection.class.should == EOL::Sparql::VirtuosoClient
  end

  it 'should to_underscore' do
    EOL::Sparql.to_underscore('Some thing').should == 'some_thing'
    EOL::Sparql.to_underscore('SomeThing').should == 'something'
    EOL::Sparql.to_underscore('Some  Thing').should == 'some_thing'
    EOL::Sparql.to_underscore('   Some  Thing  ').should == 'some_thing'
  end

  it 'should uri_to_readable_label' do
    EOL::Sparql.uri_to_readable_label('http://example.com/grams').should == 'Grams'
    EOL::Sparql.uri_to_readable_label('http://example.com/one_a_day').should == 'One A Day'
    EOL::Sparql.uri_to_readable_label('http://example.com/oneADay').should == 'One A Day'
    EOL::Sparql.uri_to_readable_label('http://example.com/59ADay').should == '59 A Day'
    EOL::Sparql.uri_to_readable_label('http://example.com#some-thing').should == 'Some Thing'
    EOL::Sparql.uri_to_readable_label('http://example.com#just-1-more').should == 'Just 1 More'
  end

  it 'should get_unit_components_from_metadata' do
    # when there is a unit in the metadata, there must be a matching KnownURI
    EOL::Sparql.get_unit_components_from_metadata({ 'http://rs.tdwg.org/dwc/terms/measurementUnit' =>
      'http://example.com/grams' }).should == nil
    KnownUri.gen_if_not_exists(:uri => 'http://example.com/grams', :name => 'grams', :is_unit_of_measure => true)
    EOL::Sparql.get_unit_components_from_metadata({ 'http://rs.tdwg.org/dwc/terms/measurementUnit' =>
      'http://example.com/grams' }).should == { :uri => "http://example.com/grams", :label => "grams" }
  end

  it 'should components_of_unit_of_measure_label_for_uri' do
    EOL::Sparql.components_of_unit_of_measure_label_for_uri('http://example.com/length').should == nil
    KnownUri.gen_if_not_exists(:uri => 'http://example.com/length', :name => 'length', :has_unit_of_measure => 'http://example.com/meters')
    EOL::Sparql.components_of_unit_of_measure_label_for_uri('http://example.com/length').should == nil
    KnownUri.gen_if_not_exists(:uri => 'http://example.com/meters', :name => 'meters', :is_unit_of_measure => true)
    EOL::Sparql.components_of_unit_of_measure_label_for_uri('http://example.com/length')
      .should == { :uri => "http://example.com/meters", :label => "meters" }
  end

  it 'should implied_unit_of_measure_for_uri' do
    EOL::Sparql.implied_unit_of_measure_for_uri('http://example.com/height').should == nil
    KnownUri.gen_if_not_exists(:uri => 'http://example.com/height', :name => 'length', :has_unit_of_measure => 'http://example.com/meters')
    EOL::Sparql.implied_unit_of_measure_for_uri('http://example.com/height').should == 'http://example.com/meters'
    EOL::Sparql.implied_unit_of_measure_for_uri(KnownUri.find_by_uri('http://example.com/height')).should == 'http://example.com/meters'

    random_known_uri = KnownUri.gen_if_not_exists(:uri => 'http://example.com/width', :name => 'width')
    EOL::Sparql.implied_unit_of_measure_for_uri(random_known_uri).should == nil
  end

  it 'should is_known_unit_of_measure_uri' do
    EOL::Sparql.is_known_unit_of_measure_uri('http://example.com/gallons').should == nil
    KnownUri.gen_if_not_exists(:uri => 'http://example.com/gallons', :name => 'gallons', :is_unit_of_measure => true)
    EOL::Sparql.is_known_unit_of_measure_uri('http://example.com/gallons').should == KnownUri.find_by_uri('http://example.com/gallons')
    EOL::Sparql.is_known_unit_of_measure_uri(KnownUri.find_by_uri('http://example.com/gallons')).should ==
      KnownUri.find_by_uri('http://example.com/gallons')
  end

  it 'should uri_components' do
    EOL::Sparql.uri_components('http://example.com/potatoes').should == { :uri => 'http://example.com/potatoes', :label => 'Potatoes' }
    known = KnownUri.gen_if_not_exists(:uri => 'http://example.com/potatoes', :name => 'Potatoes')
    EOL::Sparql.uri_components(known).should == { :uri => 'http://example.com/potatoes', :label => 'Potatoes' }
    EOL::Sparql.uri_components('nonsense').should == { :uri => 'nonsense', :label => 'nonsense' }
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
    EOL::Sparql.expand_namespaces("eol:something").should == "http://eol.org/schema/terms/something"
    EOL::Sparql.expand_namespaces("EOL:something").should == "http://eol.org/schema/terms/something"
    EOL::Sparql.expand_namespaces("dwc:something").should == "http://rs.tdwg.org/dwc/terms/something"
    EOL::Sparql.expand_namespaces("DWC:SOMETHING").should == "http://rs.tdwg.org/dwc/terms/SOMETHING"
    EOL::Sparql.expand_namespaces("http://eol.org/schema/terms/something").should == "http://eol.org/schema/terms/something"
    EOL::Sparql.expand_namespaces("<http://eol.org/schema/terms/something>").should == "http://eol.org/schema/terms/something"
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

  it 'should count_triples_in_graph' do
    drop_all_virtuoso_graphs
    EOL::Sparql.count_triples_in_graph("fictional_graph").should == 0
    EOL::Sparql.count_triples_in_graph(UserAddedData::GRAPH_NAME).should == 0
    UserAddedData.gen
    EOL::Sparql.count_triples_in_graph(UserAddedData::GRAPH_NAME).should == 4
  end
end

