# encoding: utf-8
require File.dirname(__FILE__) + '/../../spec_helper'

describe EOL::Api::MethodVersion do

  it "should thow errors when required parameters are missing" do
    EOL::Api::Ping::V1_0.stub(:parameters).and_return([ EOL::Api::DocumentationParameter.new(
      name: 'id',
      type: Integer,
      required: true ) ] )
    lambda { EOL::Api::Ping::V1_0.validate_and_normalize_input_parameters!({ }) }.should raise_error(EOL::Exceptions::ApiException, 'Required parameter "id" was not included')

    EOL::Api::Ping::V1_0.stub(:parameters).and_return([ EOL::Api::DocumentationParameter.new(
        name: 'text',
        type: String,
        required: true ) ] )
    lambda { EOL::Api::Ping::V1_0.validate_and_normalize_input_parameters!({ }) }.should raise_error(EOL::Exceptions::ApiException, 'Required parameter "text" was not included')
  end

  it 'should limit input values to ranges' do
    EOL::Api::Ping::V1_0.stub(:parameters).and_return([  EOL::Api::DocumentationParameter.new(
        name: 'ranged_integer',
        type: Integer,
        values: (50..100) ) ] )
    EOL::Api::Ping::V1_0.validate_and_normalize_input_parameters!({ 'ranged_integer' => '1' })[:ranged_integer].should == 50
    EOL::Api::Ping::V1_0.validate_and_normalize_input_parameters!({ 'ranged_integer' => '1000' })[:ranged_integer].should == 100
  end

  it 'should limit input values to arrays' do
    EOL::Api::Ping::V1_0.stub(:parameters).and_return([  EOL::Api::DocumentationParameter.new(
        name: 'array_values',
        type: String,
        default: 'two',
        values: [ 'one', 'two' ] ) ] )
    EOL::Api::Ping::V1_0.validate_and_normalize_input_parameters!({ 'array_values' => 'one' })[:array_values].should == 'one'
    EOL::Api::Ping::V1_0.validate_and_normalize_input_parameters!({ })[:array_values].should == 'two'
    EOL::Api::Ping::V1_0.validate_and_normalize_input_parameters!({ 'array_values' => 'something different' })[:array_values].should == 'two'
  end

  it 'should verify integers' do
    EOL::Api::Ping::V1_0.stub(:parameters).and_return([  EOL::Api::DocumentationParameter.new(
        name: 'some_integer',
        type: Integer,
        default: 100 ) ] )
    EOL::Api::Ping::V1_0.validate_and_normalize_input_parameters!({ 'some_integer' => '12345' })[:some_integer].should == 12345
    EOL::Api::Ping::V1_0.validate_and_normalize_input_parameters!({ 'some_integer' => '0' })[:some_integer].should == 0
    EOL::Api::Ping::V1_0.validate_and_normalize_input_parameters!({ })[:some_integer].should == 100
    EOL::Api::Ping::V1_0.validate_and_normalize_input_parameters!({ 'some_integer' => 'some string' })[:some_integer].should == 100
  end

  it 'should verify booleans' do
    EOL::Api::Ping::V1_0.stub(:parameters).and_return([  EOL::Api::DocumentationParameter.new(
        name: 'some_boolean',
        type: 'Boolean' ) ] )
    EOL::Api::Ping::V1_0.validate_and_normalize_input_parameters!({ 'some_boolean' => 'false' })[:some_boolean].should == false
    EOL::Api::Ping::V1_0.validate_and_normalize_input_parameters!({ 'some_boolean' => '0' })[:some_boolean].should == false
    EOL::Api::Ping::V1_0.validate_and_normalize_input_parameters!({ 'some_boolean' => nil })[:some_boolean].should == false
    EOL::Api::Ping::V1_0.validate_and_normalize_input_parameters!({ 'some_boolean' => '' })[:some_boolean].should == false
    EOL::Api::Ping::V1_0.validate_and_normalize_input_parameters!({ 'some_boolean' => 'true' })[:some_boolean].should == true
    EOL::Api::Ping::V1_0.validate_and_normalize_input_parameters!({ 'some_boolean' => 'on' })[:some_boolean].should == true
    EOL::Api::Ping::V1_0.validate_and_normalize_input_parameters!({ 'some_boolean' => 'anything else' })[:some_boolean].should == true
    EOL::Api::Ping::V1_0.validate_and_normalize_input_parameters!({ })[:some_boolean].should == false
  end

  it 'should default empty strings to nil' do
    EOL::Api::Ping::V1_0.stub(:parameters).and_return([  EOL::Api::DocumentationParameter.new(
        name: 'some_string',
        type: String ) ] )
    EOL::Api::Ping::V1_0.validate_and_normalize_input_parameters!({ 'some_string' => 'anything' })[:some_string].should == 'anything'
    EOL::Api::Ping::V1_0.validate_and_normalize_input_parameters!({ 'some_string' => '' })[:some_string].should == nil
  end

  it 'should return other versions' do
    stub_const("EOL::Api::Ping::VERSIONS", [ '1.0', '2.0', '3.0' ])
    stub_const("EOL::Api::Ping::V1_0::VERSION", '1.0')
    debugger unless EOL::Api::Ping::V1_0.respond_to?(:other_versions) # Hmmmn... only happens VERY rarely and only (I think)
                                                                      # immediately after making a scenario.
    EOL::Api::Ping::V1_0.other_versions.should == [ '2.0', '3.0' ]
  end

  it 'should return its method name' do
    EOL::Api::Ping::V1_0.method_name.should == 'ping'
  end
end
