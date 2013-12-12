# encoding: utf-8
require File.dirname(__FILE__) + '/../../spec_helper'

describe EOL::Api::DocumentationParameter do

  it "should get created" do
    attributes = {
      name: 'param',
      type: String,
      required: false,
      values: [ 'one', 'two'],
      default: 'two',
      notes: 'its a parameter',
      test_value: 'one' }
    p = EOL::Api::DocumentationParameter.new(attributes)
    attributes.each do |key, value|
      p.instance_variable_get("@#{key}").should == value
    end
  end

  it "should check if its an Integer" do
    EOL::Api::DocumentationParameter.new(type: Integer).integer?.should == true
    EOL::Api::DocumentationParameter.new(type: String).integer?.should == false
  end

  it "should check if its a String" do
    EOL::Api::DocumentationParameter.new(type: String).string?.should == true
    EOL::Api::DocumentationParameter.new(type: Integer).string?.should == false
  end

  it "should check if its a Boolean" do
    EOL::Api::DocumentationParameter.new(type: 'Boolean').boolean?.should == true
    EOL::Api::DocumentationParameter.new(type: Integer).boolean?.should == false
  end

  it "should check if its an Array" do
    EOL::Api::DocumentationParameter.new(values: [ 'test', 'values' ]).array?.should == true
    EOL::Api::DocumentationParameter.new(values: 'test, values').array?.should == false
  end

  it "should check if its a Range" do
    EOL::Api::DocumentationParameter.new(values: (0..75)).range?.should == true
    EOL::Api::DocumentationParameter.new(values: '0-75').range?.should == false
  end

  it "should check if its required" do
    EOL::Api::DocumentationParameter.new(required: true).required?.should == true
    EOL::Api::DocumentationParameter.new(required: false).required?.should == false
  end

  it "should default booleans to false" do
    EOL::Api::DocumentationParameter.new(default: nil, type: 'Boolean').default.should === false
    EOL::Api::DocumentationParameter.new(default: nil).default.should === nil
    EOL::Api::DocumentationParameter.new(default: 0).default.should === 0
  end
end
