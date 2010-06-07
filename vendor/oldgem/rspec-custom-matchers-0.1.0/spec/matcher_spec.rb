require File.dirname(__FILE__) + '/spec_helper'

include CustomMatcher::Helper

matcher(:be_divisible_by) { |number, divisor| number % divisor == 0 }
matcher(:be_even) {|even| even % 2 == 0}
matcher(:be_odd) {|odd| odd % 2 != 0}
matcher(:be_equal_to)

describe "6" do
  it "should be divisible by 3" do
    6.should be_divisible_by(3)
  end

  it "should be divisible by 2" do
    6.should be_divisible_by(2)
  end
  
  it "should not be divisible by 12" do
    6.should_not be_divisible_by(12)
  end
  
  it "should be even" do
    6.should be_even
  end
  
  it "should not be odd" do
    6.should_not be_odd
  end
  
  it "should be equal to 6" do
    6.should be_equal_to(6)
  end

  it "should not be equal to 7" do
    6.should_not be_equal_to(7)
  end
end
