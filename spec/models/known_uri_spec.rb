require File.dirname(__FILE__) + '/../spec_helper'

describe KnownUri do

  before :all do
    Vetted.create_defaults
    Visibility.create_defaults
    UriType.create_defaults
    @measurement = FactoryGirl.create(:known_uri_measurement)
    @value_1 = FactoryGirl.create(:known_uri_value)
    FactoryGirl.create(:known_uri_allowed_value, from_known_uri: @measurement, to_known_uri: @value_1)
    @value_2 = FactoryGirl.create(:known_uri_value)
    FactoryGirl.create(:known_uri_allowed_value, from_known_uri: @measurement, to_known_uri: @value_2)
    @value_3 = FactoryGirl.create(:known_uri_value) # not related
    @unit_1 = FactoryGirl.create(:known_uri_unit)
    FactoryGirl.create(:known_uri_allowed_unit, from_known_uri: @measurement, to_known_uri: @unit_1)
    @unit_2 = FactoryGirl.create(:known_uri_unit)
    FactoryGirl.create(:known_uri_allowed_unit, from_known_uri: @measurement, to_known_uri: @unit_2)
    @unit_3 = FactoryGirl.create(:known_uri_unit)
    @measurement.reload
  end

  it 'should know about its allowed values' do
    @measurement.allowed_values.should include(@value_1)
    @measurement.allowed_values.should include(@value_2)
    @measurement.allowed_values.should_not include(@value_3)
    @measurement.allowed_values.should_not include(@unit_1)
  end

  it 'should know about its allowed units' do
    @measurement.allowed_units.should include(@unit_1)
    @measurement.allowed_units.should include(@unit_2)
    @measurement.allowed_units.should_not include(@unit_3)
    @measurement.allowed_units.should_not include(@value_1)
  end

end

