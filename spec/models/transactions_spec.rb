require File.dirname(__FILE__) + '/../spec_helper'

# this appears in model specs & in blackbox specs (for now) 
# just to be certain that the type of spec doesn't matter ...
#
# once we're fully certain, we'll kill the symlink that runs this as a blackbox spec

# this tests to make sure transactions are working 
# properly in our spec suite.  if this blows up, 
# it's likely that lots of other specs will all blow up
describe 'RSpec Transactions' do

  before :all do
    truncate_all_tables # shouldn't need this!
  end

  # make sure that transactions are working 
  # for all of the different databases
  #
  # we're using a few models from each database 
  # just incase it's the model there's a problem 
  # with and not the database, itself
  #
  # NOTE the Logging database's tables use MyISAM and 
  #      therefore do NOT support transactions!
  #
  {
    'Rails Database'   => [ User, ContentPage, Role ],
    'Data Database'    => [ Visibility, Name, Agent ]
  
  }.each do |database, models|

    describe database do

      models.each do |model|

        it "should have no #{ model.to_s.tableize } are the start of an example" do
          model.count.should == 0
          3.times { model.gen }
          model.count.should == 3
        end

        it "should *still* have no #{ model.to_s.tableize } are the start of an example" do
          model.count.should == 0
          3.times { model.gen }
          model.count.should == 3
        end

      end

    end

  end
  
  # NOTE: These got screwed up once we started needing the foundation scenario to
  # build models.  So... I am making them pending.  I'm not entirely sure we *care*
  # about these tests, but this is for later review.  (TODO)
   
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
