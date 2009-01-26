require File.dirname(__FILE__) + '/../spec_helper'

# This should exercise implementations of the abstract class LogDaily
#
# I want to be able to easily define new LogDaily classes and have 
# them work essentially out-of-the-box, altho they'll need tables 
# in the _logging database to actually be mined properly.

# TODO i think this might be getting too big?  i might wanna split out into a few specs?

# this is the conrete LogDaily implementation we'll be testing
class UserAgentLogDaily < LogDaily
  set_unique_data_column :string, :user_agent
end

# Migration class to use for creating user_agent_log_dailies
class ExampleLoggingMigration < ActiveRecord::Migration
  def self.database_model() "LoggingModel" end
end

describe LogDaily, 'migration helpers' do

  before(:all) do
    DataType.create_valid
    UserAgentLogDaily.drop_table ExampleLoggingMigration if UserAgentLogDaily.table_exists?
  end

  it '#create_table should create path_log_dailies properly' do
    UserAgentLogDaily.table_exists?.should be_false
    UserAgentLogDaily.create_table ExampleLoggingMigration
    UserAgentLogDaily.table_exists?.should be_true
    lambda {  
      UserAgentLogDaily.create LogDaily.valid_attributes({ :agent_id => 1 })
    }.should change(UserAgentLogDaily, :count).by(1)
  end

end

describe LogDaily do

  before(:all) do
    @image_data_type = DataType.create :label => 'Image', :schema_value => ''

    # all LogDaily classes validate presence of :data_type, :created_at, :total, :agent
    @valid_attributes = {
      :day => Date.today,
      :total => 0,
      :data_type => @image_data_type,
      :user_agent => 'Mozilla/Firefox',
      :agent_id => 1
    }
  end

  before :all do
    UserAgentLogDaily.create_table ExampleLoggingMigration
  end

  it '#mine_data data should return all of the data to mine from data_object_logs' do
    UserAgentLogDaily.mine_data.should be_empty

    %w( A A A B B C ).each do |user_agent|
      DataObjectLog.create_valid :user_agent => user_agent
    end

    mine_data = UserAgentLogDaily.mine_data
    mine_data.length.should == 3 # note, the .total column returns a string integer at the moment (?)
    mine_data.find {|data| data.user_agent == 'A' }.total.should == 3
    mine_data.find {|data| data.user_agent == 'C' }.total.should == 1
  end

  it '#mine_data RANGE should return the a range of data to mine from data_object_logs' do
    %w( A A A B B C ).each do |user_agent|
      DataObjectLog.create_valid :user_agent => user_agent, :created_at => D['01/15/2000']
    end
    %w( A A A X X Y Z ).each do |user_agent|
      DataObjectLog.create_valid :user_agent => user_agent, :created_at => D['01/20/2000']
    end

    UserAgentLogDaily.mine_data( D['01/15/2000']..D['01/19/2000'] ).length.should == 3
    UserAgentLogDaily.mine_data( D['01/20/2000']..D['01/20/2000'] ).length.should == 4
    UserAgentLogDaily.mine_data( D['01/15/2000']..D['01/20/2000'] ).length.should == 7
  end

  it '#mine should mine ALL data from data_object_logs' do
    %w( A A A B B C ).each do |user_agent|
      DataObjectLog.create_valid :user_agent => user_agent
    end
    DataObjectLog.count.should == 6 # just incase this is blowing up ...

    UserAgentLogDaily.count.should == 0
    UserAgentLogDaily.mine
    UserAgentLogDaily.count.should == 3
    UserAgentLogDaily.mine
    UserAgentLogDaily.count.should == 3
  end

  it '#mine RANGE should should mine a range of data from data_object_logs' do
    %w( A A A B B C ).each do |user_agent|
      DataObjectLog.create_valid :user_agent => user_agent, :created_at => D['01/15/2000']
    end
    %w( A A A X X Y Z ).each do |user_agent|
      DataObjectLog.create_valid :user_agent => user_agent, :created_at => D['01/20/2000']
    end

    UserAgentLogDaily.count.should == 0
    UserAgentLogDaily.mine D['01/15/2000']..D['01/15/2000']
    UserAgentLogDaily.count.should == 3
    UserAgentLogDaily.mine D['01/15/2000']..D['01/20/2000']
    UserAgentLogDaily.count.should == 7
  end

  it '#grand_totals should return the sum of all #total' do
    %w( A A A B B C ).each do |user_agent|
      DataObjectLog.create_valid :user_agent => user_agent
    end

    UserAgentLogDaily.mine

    totals = UserAgentLogDaily.grand_totals
    totals.length.should == 3
    totals.find {|total| total.unique_data == 'A' }.total.should == 3
    totals.find {|total| total.user_agent  == 'B' }.total.should == 2
  end

  it '#grand_totals RANGE should return the sum of all #total for a given range' do
    %w( A A A B B C ).each do |user_agent|
      DataObjectLog.create_valid :user_agent => user_agent, :created_at => D['01/15/2000']
    end
    %w( A A A X X Y Z ).each do |user_agent|
      DataObjectLog.create_valid :user_agent => user_agent, :created_at => D['01/20/2000']
    end

    UserAgentLogDaily.mine

    UserAgentLogDaily.grand_totals(D['01/15/2000']..D['01/16/2000']).length.should == 3
    UserAgentLogDaily.grand_totals(D['01/16/2000']..D['01/20/2000']).length.should == 4
    UserAgentLogDaily.grand_totals(D['01/15/2000']..D['01/20/2000']).length.should == 6
  end

  it 'should support pagination' do
    (1..20).each do |i|
      UserAgentLogDaily.create @valid_attributes.merge({ :user_agent => "UserAgent#{i}" })
    end

    UserAgentLogDaily.grand_totals.length.should == 20
    UserAgentLogDaily.grand_totals( nil, :page => 1, :per_page => 10 ).length.should == 10
    UserAgentLogDaily.grand_totals( :page => 1 ).length.should == 10
    UserAgentLogDaily.grand_totals( :page => 1 ).total_pages.should == 2
  end

  it 'should log each item unique to agent_id (and unique_data, day, & data_type_id)' do
    %w( A A B B C ).each do |user_agent|
      DataObjectLog.create_valid :user_agent => user_agent, :agent_id => 1
    end
    %w( A A ).each do |user_agent|
      DataObjectLog.create_valid :user_agent => user_agent, :agent_id => 1, :created_at => D['12/31/1999'] # so we can do a test with Ranges too
    end
    %w( A A A A B B ).each do |user_agent|
      DataObjectLog.create_valid :user_agent => user_agent, :agent_id => 2
    end
    DataObjectLog.count.should == 13 # just incase this doesn't behave as expected

    UserAgentLogDaily.mine
    UserAgentLogDaily.count.should == 6
    UserAgentLogDaily.grand_totals.length.should == 3
    UserAgentLogDaily.grand_totals( :agent => 1 ).length.should == 3
    UserAgentLogDaily.grand_totals( :agent => 2 ).length.should == 2
    UserAgentLogDaily.grand_totals( D['12/31/1999']..D['12/31/1999'], :agent => 1 ).length.should == 1

    # i'd like to also be able to: (just some ideas)
    #
    #   UserAgentLogDaily.grand_totals( D['12/31/1999'], :agent => 1 )
    #   UserAgentLogDaily.grand_totals( D['12/31/1999']..D['12/31/1999'], :agent => 1, :data_type => 4 )
    #   UserAgentLogDaily.grand_totals( D['12/31/1999']..D['12/31/1999'], :agent => 1, :data_type => DataType::PNG_IMAGE )
  end

  it 'should log each item unique to data_type (and unique_data, day, & agent_id)'

  # if we can pass along additional filtering conditions then we can do things like
  # say #grand_totals :user_agent => 'A'
  # or  #grand_totals :conditions => ['user_agent = :user_agent', { :user_agent => 'A'}]
  #
  # this would be kinda convenient.  altho we could get a similar result by 
  # calling #find on the LogDaily class, itself
  it '#grand_totals should accept additional :conditions (???)'

  # this needs to be an optimized query that just returns the TOP results
  # with percentages already calculated by the mysql query
  it '#grand_totals should return a percentage for each item' do
    
    # mock 90 unique user agents
    (1..10).each do |user_agent|
      DataObjectLog.create_valid :user_agent => user_agent.to_s
    end

    # mock 10 manually, each of which will represent 5% of the total
    %w( A A A A A B B C D D ).each do |user_agent|
      DataObjectLog.create_valid :user_agent => user_agent
    end

    UserAgentLogDaily.mine

    totals = UserAgentLogDaily.grand_totals :include_percentage => true
    totals.length.should == 14 # all of the different user_agents
    totals.first.user_agent.should == 'A'
    totals.first.percentage.should == 25
    totals[1].user_agent.should == 'B'
    totals[1].percentage.should == 10

    # now, we should also be able to limit the whole thing but still get the same percentages
    totals = UserAgentLogDaily.grand_totals :limit => 10, :include_percentage => true
    totals.length.should == 10 # all of the different user_agents
    totals.first.user_agent.should == 'A'
    totals.first.percentage.should == 25.0
    totals[1].user_agent.should == 'B'
    totals[1].percentage.should == 10.0
  end

end
