require "spec_helper"

describe KnownUri do

  before(:all) do
    populate_tables(:vetted, :visibilities, :uri_types)
    Language.create_english
    @unit_of_measure = KnownUri.gen_if_not_exists(uri: Rails.configuration.uri_measurement_unit, name: 'Unit of Measure')
  end

  # TODO - I added #first to all these calls because I changed the interface.  Fix.
  context '#by_name' do

    before(:each) do
      @uri1 = double(KnownUri, position: 1, name: 'baz boozer')
      allow(@uri1).to receive(:is_a?).with(KnownUri).and_return(true)
      @uri2 = double(KnownUri, position: 2, name: 'bar baz')
      allow(@uri2).to receive(:is_a?).with(KnownUri).and_return(true)
      @uri3 = double(KnownUri, position: 3, name: 'Foo bar')
      allow(@uri3).to receive(:is_a?).with(KnownUri).and_return(true)
      @uris = [@uri1, @uri2, @uri3]
    end

    it 'should find an exact match' do
      EOL::Sparql.connection.should_receive(:all_measurement_type_known_uris).and_return(@uris)
      expect(KnownUri.by_name('bar baz').first).to eq(@uri2)
    end

    it 'should ignore case' do
      EOL::Sparql.connection.should_receive(:all_measurement_type_known_uris).and_return(@uris)
      expect(KnownUri.by_name('foo BAR').first).to eq(@uri3)
    end

    it 'should ignore extra space' do
      EOL::Sparql.connection.should_receive(:all_measurement_type_known_uris).and_return(@uris)
      expect(KnownUri.by_name('Foo    bar').first).to eq(@uri3)
    end

    it 'should match the first single word' do
      EOL::Sparql.connection.should_receive(:all_measurement_type_known_uris).and_return(@uris)
      expect(KnownUri.by_name('bar').first).to eq(@uri2) # Not 3...
    end

    it 'should ignore symbols' do
      EOL::Sparql.connection.should_receive(:all_measurement_type_known_uris).and_return(@uris)
      expect(KnownUri.by_name('foo$#').first).to eq(@uri3)
    end

    # NOTE - I fixed this one already (given the TODO above). Just remove this comment.
    it 'should return empty set with no match' do
      EOL::Sparql.connection.should_receive(:all_measurement_type_known_uris).and_return([])
      expect(KnownUri.by_name('anything')).to eq([])
    end

    it 'should ignore sparql results that are not URIs' do
      EOL::Sparql.connection.should_receive(:all_measurement_type_known_uris).and_return(['perfect'])
      expect(KnownUri.by_name('perfect').first).to be_nil
    end

  end

  it 'should find UnitOfMeasure' do
    expect(KnownUri.unit_of_measure).to eq(@unit_of_measure)
  end

  it 'should create custom URIs' do
    kn = KnownUri.custom('Body length', Language.english)
    expect(kn.name).to eq('Body length')
    expect(kn.uri).to eq(Rails.configuration.uri_term_prefix + 'body_length')
  end

  it 'should extract taxon_concept_ids' do
    expect(KnownUri.taxon_concept_id('http://eol.org/pages/1234')).to eq('1234')
    expect(KnownUri.taxon_concept_id('http://www.eol.org/pages/1234')).to eq('1234')
    expect(KnownUri.taxon_concept_id('http://eol.org/pages/1234/data')).to eq('1234')
    expect(KnownUri.taxon_concept_id('http://eol.org/data_objects/1234')).to eq(false)
    expect(KnownUri.taxon_concept_id('http://eol.org/1234')).to eq(false)
  end

  it 'should list allowed values' do
    kn = KnownUri.gen
    value_kn = KnownUri.gen(uri_type: UriType.value)
    expect(kn.allowed_values).to eq([])
    expect(kn.has_values?).to eq(false)
    KnownUriRelationship.gen(from_known_uri: kn, relationship_uri: KnownUriRelationship::ALLOWED_VALUE_URI, to_known_uri: value_kn)
    kn = KnownUri.find(kn)
    expect(kn.allowed_values).to eq([ value_kn ])
    expect(kn.has_values?).to eq(true)
  end

  it 'should list allowed units' do
    kn = KnownUri.gen
    unit_kn = KnownUri.gen(uri_type: UriType.value)
    expect(kn.allowed_units).to eq([])
    expect(kn.has_units?).to eq(false)
    KnownUriRelationship.gen(from_known_uri: kn, relationship_uri: KnownUriRelationship::ALLOWED_UNIT_URI, to_known_uri: unit_kn)
    # resetting the instance
    kn = KnownUri.find(kn)
    expect(kn.allowed_units).to eq([ unit_kn ])
    expect(kn.has_units?).to eq(true)
  end

  it 'should be unknown if the name is blank' do
    kn = KnownUri.gen_if_not_exists(name: 'Anything')
    expect(kn.name.blank?).to eq(false)
    expect(kn.unknown?).to eq(false)
    kn.translations.destroy_all
    # resetting the instance
    kn = KnownUri.find(kn)
    expect(kn.name.blank?).to eq(true)
    expect(kn.unknown?).to eq(true)
  end

  it 'should return an implied unit of measure' do
    kn = KnownUri.gen
    implied_unit_kn = KnownUri.gen(uri_type: UriType.value)
    KnownUriRelationship.gen(from_known_uri: @unit_of_measure, relationship_uri: KnownUriRelationship::ALLOWED_VALUE_URI, to_known_uri: implied_unit_kn)
    expect(kn.implied_unit_of_measure).to eq(nil)
    KnownUriRelationship.gen(from_known_uri: kn, relationship_uri: KnownUriRelationship::MEASUREMENT_URI, to_known_uri: implied_unit_kn)
    kn.reload
    expect(kn.implied_unit_of_measure).to eq(implied_unit_kn)
  end

  it 'should know if it matches another KnownUri (by URI)' do
    kn = KnownUri.gen(uri: 'http://eol.org/test')
    expect(kn.matches('http://eol.org/test')).to eq(true)
    expect(kn.matches('http://EOL.org/test')).to eq(true)
    expect(kn.matches('HTTP://EOL.ORG/TEST')).to eq(true)
    expect(kn.matches('http://www.eol.org/test')).to eq(false)
  end

  it 'should know when URIs are units of measure' do
    implied_unit_kn = KnownUri.gen(uri_type: UriType.value)
    expect(implied_unit_kn.unit_of_measure?).to eq(false)
    KnownUriRelationship.gen(from_known_uri: @unit_of_measure, relationship_uri: KnownUriRelationship::ALLOWED_VALUE_URI, to_known_uri: implied_unit_kn)
    Rails.cache.clear
    expect(implied_unit_kn.unit_of_measure?).to eq(true)
  end

  it 'should generate an anchor string'

  it 'should add_to_triplestore'

  it 'should remove_from_triplestore'

  it 'should update_triplestore'

  it 'should generate a proper RDF Turtle'

  it 'removes leading and trailing whitespaces' do 
    uri ="\t\t"+Rails.configuration.uri_term_prefix+"anything   "
    known_uri= KnownUri.gen(uri: uri)
    expect(known_uri.uri).to eq(Rails.configuration.uri_term_prefix+"anything")
  end

  context "treat as string" do
    it "doesn't format data value for verbatim known uris" do 
      
    end
    
  end
end
