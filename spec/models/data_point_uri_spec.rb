require 'spec_helper'

def make_and_convert(options)
  d = DataPointUri.new(options)
  d.convert_units
  d
end

describe DataPointUri do
  before(:all) do
    load_foundation_cache
  end

  it 'should hide/show user_added_data when hidden/show' do
    d = DataPointUri.gen()
    d.reload  # not exactly sure why the reload is necessary here, but it was failing without it
    d.visibility_id.should == Visibility.visible.id
    d.user_added_data.visibility_id.should == Visibility.visible.id
    d.hide(User.last)
    d.visibility_id.should == Visibility.invisible.id
    d.user_added_data.visibility_id.should == Visibility.invisible.id
    d.show(User.last)
    d.visibility_id.should == Visibility.visible.id
    d.user_added_data.visibility_id.should == Visibility.visible.id
  end

  it 'should create a proper anchor' do
    d = DataPointUri.gen
    d.id.should >= 1
    d.anchor.should == "data_point_#{d.id}"
  end

  it 'should use the right source' do
    user_added_data = UserAddedData.gen
    user_added_data.data_point_uri.source.should == user_added_data.user

    r = Resource.gen
    d = DataPointUri.gen(:user_added_data => nil, :resource => r)
    d.source.should == r.content_partner
  end

  it 'should predicate_uri' do
    d = DataPointUri.gen(:predicate_known_uri => nil, :predicate => 'mass')
    d.predicate_uri.should == 'mass'
    known_uri = KnownUri.gen
    d = DataPointUri.gen(:predicate_known_uri => known_uri, :predicate => 'mass')
    d.predicate_uri.should == known_uri
  end

  it 'should object_uri' do
    d = DataPointUri.gen(:object_known_uri => nil, :object => 'North America')
    d.object_uri.should == 'North America'
    known_uri = KnownUri.gen
    d = DataPointUri.gen(:object_known_uri => known_uri, :object => 'North America')
    d.object_uri.should == known_uri
  end

  it 'should unit_of_measure_uri' do
    d = DataPointUri.gen(:unit_of_measure_known_uri => nil, :unit_of_measure => 'grams')
    d.unit_of_measure_uri.should == 'grams'
    known_uri = KnownUri.gen
    d = DataPointUri.gen(:unit_of_measure_known_uri => known_uri, :unit_of_measure => 'grams')
    d.unit_of_measure_uri.should == known_uri
  end

  it 'should measurement?' do
    DataPointUri.gen(class_type: 'MeasurementOrFact').measurement?.should == true
    DataPointUri.gen(class_type: 'Association').measurement?.should == false
    DataPointUri.gen(class_type: 'Nonsense').measurement?.should == false
  end

  it 'should association?' do
    DataPointUri.gen(class_type: 'MeasurementOrFact').association?.should == false
    DataPointUri.gen(class_type: 'Association').association?.should == true
    DataPointUri.gen(class_type: 'Nonsense').association?.should == false
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
    # Kelvin
    d = make_and_convert(object: 700, unit_of_measure_known_uri: KnownUri.kelvin)
    d.object.should == 426.85
    d.unit_of_measure_known_uri.should == KnownUri.celsius
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
end
