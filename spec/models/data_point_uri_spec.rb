require "spec_helper"

def make_and_convert(options)
  d = Trait.new(options)
  d.convert_units
  d
end


def create_measurement_from_name(taxon_name)
  measurement = DataMeasurement.new(subject: TaxonConcept.gen, resource: Resource.gen,
    predicate: KnownUri.gen.uri, object: 'whatever', taxon_name: taxon_name)
  measurement.update_triplestore
  measurement
end


describe Trait do
  before(:all) do
    load_foundation_cache
    # These don't cut it. Sigh. Some data from foundation really IS needed, but shouldn't be.
    # Language.create_english
    # Vetted.create_enumerated
    # Visibility.create_enumerated
    # ContentPartnerStatus.create_enumerated
    # License.create_enumerated
    # UriType.create_enumerated
    # KnownUri.create_enumerated
  end
  
  it 'should hide/show user_added_data when hidden/show' do
    d = Trait.gen()
    d.reload  # TODO - this shouldn't be needed; but #hide doesn't work without it. I couldn't figure out why, but was rushing.
              # app/models/trait.rb - where #hide is defined
              # lib/eol/curatable_association.rb - where the set_visibility is defined
    d.visibility_id.should == Visibility.visible.id
    d.user_added_data.visibility_id.should == Visibility.visible.id
    d.hide(User.last)
    d.visibility_id.should == Visibility.invisible.id
    d.user_added_data.visibility_id.should == Visibility.invisible.id
    d.show(User.last)
    d.visibility_id.should == Visibility.visible.id
    d.user_added_data.visibility_id.should == Visibility.visible.id
  end

  it 'should sort exemplars first' do
    uris = FactoryGirl.create_list(:trait, 5, taxon_concept_id: 1)
    last = uris.last
    expect(uris.sort.first).to_not eq(last)
    last.taxon_data_exemplars << TaxonDataExemplar.new(trait: last, exclude: false, taxon_concept_id: 1)
    expect(uris.sort.first).to eq(last)
  end

  it 'should sort excluded last' do
    uris = FactoryGirl.create_list(:trait, 5, taxon_concept_id: 1)
    first = uris.first
    expect(uris.sort.last).to_not eq(first)
    first.taxon_data_exemplars << TaxonDataExemplar.new(trait: first, exclude: true, taxon_concept_id: 1)
    expect(uris.sort.last).to eq(first)
  end

  it 'should create a proper anchor' do
    d = Trait.gen
    d.id.should >= 1
    d.anchor.should == "data_point_#{d.id}"
  end

  it 'should use the right source' do
    user_added_data = UserAddedData.gen
    user_added_data.trait.source.should == user_added_data.user

    r = Resource.gen
    d = Trait.gen(user_added_data: nil, resource: r)
    d.source.should == r.content_partner
  end

  it 'should predicate_uri' do
    d = Trait.gen(predicate_known_uri: nil, predicate: 'mass')
    d.predicate_uri.should == 'mass'
    known_uri = KnownUri.gen
    d = Trait.gen(predicate_known_uri: known_uri, predicate: 'mass')
    d.predicate_uri.should == known_uri
  end

  it 'should object_uri' do
    d = Trait.gen(object_known_uri: nil, object: 'North America')
    d.object_uri.should == 'North America'
    known_uri = KnownUri.gen
    d = Trait.gen(object_known_uri: known_uri, object: 'North America')
    d.object_uri.should == known_uri
  end

  it 'should use the master for get_references' do
    Trait.should_receive(:with_master).and_return(true)
    Trait.gen.get_references(Language.english)
  end

  it 'should use the master for get_metadata' do
    Trait.should_receive(:with_master).and_return(true)
    Trait.gen.get_metadata(Language.english)
  end

  it 'should use the master for get_other_occurrence_measurements' do
    Trait.should_receive(:with_master).and_return(true)
    Trait.gen.get_other_occurrence_measurements(Language.english)
  end


  context 'with grams as unit of measure' do

    let(:with_grams) { Trait.gen(unit_of_measure_known_uri: nil, unit_of_measure: 'grams') }

    it 'should have "grams" as the unit of measure uri' do
      with_grams.unit_of_measure_uri.should == 'grams'
    end

  end

  context 'with grams as known_uri' do

    let(:grammy) { Trait.new(object: 70, unit_of_measure_known_uri: KnownUri.grams) }

    it 'should unit_of_measure_uri' do
      grammy.unit_of_measure_uri.should == KnownUri.grams
    end

    context '#to_hash' do

      let(:hashed) { grammy.to_hash }

      it 'should have the units URI' do
        expect(hashed[I18n.t(:data_column_units_uri)]).to eq(KnownUri.grams.uri)
      end

      it 'should have the units label' do
        expect(hashed[I18n.t(:data_column_units)]).to eq(KnownUri.grams.label)
      end

      it 'should have the same original units URI' do
        expect(hashed[I18n.t(:data_column_raw_units_uri)]).to eq(KnownUri.grams.uri)
      end

      it 'should have the same original units label' do
        expect(hashed[I18n.t(:data_column_raw_units)]).to eq(KnownUri.grams.label)
      end

    end

  end

  it 'should measurement?' do
    Trait.gen(class_type: 'MeasurementOrFact').measurement?.should == true
    Trait.gen(class_type: 'Association').measurement?.should == false
    Trait.gen(class_type: 'Nonsense').measurement?.should == false
  end

  it 'should association?' do
    Trait.gen(class_type: 'MeasurementOrFact').association?.should == false
    Trait.gen(class_type: 'Association').association?.should == true
    Trait.gen(class_type: 'Nonsense').association?.should == false
  end

  it 'should convert units' do
    # Grams
    d = make_and_convert(object: 1000, unit_of_measure_known_uri: KnownUri.milligrams)
    d.object.should == 1.0
    d.unit_of_measure_known_uri.should == KnownUri.grams
    d = make_and_convert(object: 2000, unit_of_measure_known_uri: KnownUri.grams)
    d.object.should == 2.0
    d.unit_of_measure_known_uri.should == KnownUri.kilograms
    d = make_and_convert(object: 3000000, unit_of_measure_known_uri: KnownUri.milligrams)
    d.object.should == 3.0
    d.unit_of_measure_known_uri.should == KnownUri.kilograms
    # Meters
    d = make_and_convert(object: 40, unit_of_measure_known_uri: KnownUri.millimeters)
    d.object.should == 4.0
    d.unit_of_measure_known_uri.should == KnownUri.centimeters
    d = make_and_convert(object: 500, unit_of_measure_known_uri: KnownUri.centimeters)
    d.object.should == 5.0
    d.unit_of_measure_known_uri.should == KnownUri.meters
    d = make_and_convert(object: 6000, unit_of_measure_known_uri: KnownUri.millimeters)
    d.object.should == 6.0
    d.unit_of_measure_known_uri.should == KnownUri.meters
  end

  context 'kelvin that should be celsius' do

    let(:kelvin) do
      kelvin = Trait.new(object: 700, unit_of_measure_known_uri: KnownUri.kelvin)
      kelvin.convert_units
      kelvin
    end

    it 'should be worth converting' do
      expect(kelvin.object).to be > 420 # Needs to be high enough to be worth converting...
    end

    it 'should convert to celsius' do
      expect(kelvin.unit_of_measure_known_uri).to eq(KnownUri.celsius)
    end

    it 'should still know the original value' do
      expect(kelvin.original_unit_of_measure_uri.name).to eq(KnownUri.kelvin.name)
    end

    context '#to_hash' do

      let(:hashed) { kelvin.to_hash }

      it 'should have the new units URI' do
        expect(hashed[I18n.t(:data_column_units_uri)]).to eq(KnownUri.celsius.uri)
      end

      it 'should have the new units label' do
        expect(hashed[I18n.t(:data_column_units)]).to eq(KnownUri.celsius.label)
      end

      it 'should have the original units URI' do
        expect(hashed[I18n.t(:data_column_raw_units_uri)]).to eq(KnownUri.kelvin.uri)
      end

      it 'should have the original units label' do
        expect(hashed[I18n.t(:data_column_raw_units)]).to eq(KnownUri.kelvin.label)
      end

    end

  end

  it 'should preserve accuracy when converting' do
    d = make_and_convert(object: 10, unit_of_measure_known_uri: KnownUri.milligrams)
    d.object.should == 10
    d = make_and_convert(object: 1000.0, unit_of_measure_known_uri: KnownUri.milligrams)
    d.object.class.should == Float
    d.object.should == 1.0
    d = make_and_convert(object: 1000, unit_of_measure_known_uri: KnownUri.milligrams)
    d.object.class.should == Float
    d.object.should == 1.0
  end

  context 'class methods' do
    context 'assign_metadata' do
      before :all do
        drop_all_virtuoso_graphs
        @name = 'Aus bus'
        @measurement = create_measurement_from_name(@name)
        @data_point = Trait.gen(uri: @measurement.uri)
      end

      it 'returns the taxon name associated with a measurement' do
        Trait.assign_metadata([ @data_point ], Language.english)
        expect(@data_point.metadata.first.predicate).to eq('http://rs.tdwg.org/dwc/terms/scientificName')
        expect(@data_point.metadata.first.object).to eq(@name)
      end
    end
  end

end
