require File.dirname(__FILE__) + '/spec_helper'

describe CustomMatcher do
  describe "subclasses, in general (initialized without a block)" do
    before(:all) do
      CustomMatcher.create(:be_an_example)
    end
    
    it "should inherit from Custom Matcher" do
      BeAnExample.superclass.should == CustomMatcher
    end
    
    it "should have the default matcher (==)" do
      BeAnExample.new(10).matches?(10).should be_true
      BeAnExample.new("10").matches?("10").should be_true
      BeAnExample.new(Object.new).matches?(Object.new).should be_false
    end
    
    it "should provide a failure message based on it's class" do
      BeAnExample.new(10).failure_message.should == "Expected nil to be an example 10"
    end

    it "should provide a negative failure message based on it's class" do
      BeAnExample.new(10).negative_failure_message.should == "Did not expect nil to be an example 10"
    end
  end
  
  describe "subclasses, initialized with a matcher block" do
    before(:all) do
      CustomMatcher.create(:be_divisible_by) do |target, expectation|
        target % expectation == 0
      end
    end
    
    it "should take use the create block as the custom matcher" do
      BeDivisibleBy.new(10).matches?(5).should be_false # 5 is NOT divisible by 10
      BeDivisibleBy.new(10).matches?(20).should be_true # 20 IS divisible by 10
    end
  end
end

