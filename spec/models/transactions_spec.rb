require File.dirname(__FILE__) + '/../spec_helper'

# this tests to make sure transactions are working 
# properly in our spec suite.  if this blows up, 
# it's likely that lots of other specs will all blow up
describe 'RSpec Database Transations' do

  it "should have no users are the start of an example" do
    User.count.should == 0
    3.times { User.gen }
    User.count.should == 3
  end

  it "should *still* have no users are the start of an example" do
    User.count.should == 0
    3.times { User.gen }
    User.count.should == 3
  end

  it "scenarios should respect transactions too" do
    Visibility.count.should == 0
    Scenario.load :foundation # load foundation
    Visibility.count.should > 0
  end

  it "scenarios should *still* respect transactions too" do
    Visibility.count.should == 0
    Scenario.load :foundation # load foundation
    Visibility.count.should > 0
  end

end
