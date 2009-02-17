require File.dirname(__FILE__) + '/../spec_helper'

# this tests to make sure transactions are working 
# properly in our spec suite.  if this blows up, 
# it's likely that lots of other specs will all blow up
describe 'RSpec Transations' do

  # make sure that transactions are working 
  # for all of the different databases
  {
    'Rails Database'   => User,
    'Data Database'    => Visibility,
    'Logging Database' => IpAddress
  
  }.each do |database, model|

    describe database do

      it "should have no users are the start of an example" do
        puts "testing transactions for #{ model.connection.instance_eval { @config[:database] } }"
        model.count.should == 0
        3.times { model.gen }
        model.count.should == 3
      end

      it "should *still* have no users are the start of an example" do
        puts "testing transactions for #{ model.connection.instance_eval { @config[:database] } }"
        model.count.should == 0
        3.times { model.gen }
        model.count.should == 3
      end

    end

  end

  it "scenarios should respect transactions too" do
    pending
    Visibility.count.should == 0
    Scenario.load :foundation # load foundation
    Visibility.count.should > 0
  end

  it "scenarios should *still* respect transactions too" do
    pending
    Visibility.count.should == 0
    Scenario.load :foundation # load foundation
    Visibility.count.should > 0
  end

end
