require File.dirname(__FILE__) + '/../spec_helper'

describe DataObjectLog do

  before :all do
    @data_object_log_count = DataObjectLog.count
  end

  it '#create_valid should be valid' do
    DataObjectLog.create_valid!.should be_valid
  end

  it 'should increment the DataObjectLog count on #create (only in this example)' do
    lambda { DataObjectLog.create_valid }.should change(DataObjectLog,:count).from(@data_object_log_count).to(@data_object_log_count + 1)
  end

  # we need 2 examples to confirm that the count doesn't change between examples
  it 'should *still* increment the DataObjectLog count on #create (only in this example)' do
    lambda { DataObjectLog.create_valid }.should change(DataObjectLog,:count).from(@data_object_log_count).to(@data_object_log_count + 1)
  end

end

describe DataObjectLog, 'with fixtures' do
  fixtures :users, :agents, :agents_data_objects

  before(:each) do
    @request = ActionController::TestRequest.new
    @request.user_agent = 'Mozilla/5.0 (Windows; U; Windows NT 5.1; en-GB; rv:1.8.1.6) Gecko/20070725 Firefox/2.0.0.6'
    @request.stub!(:remote_ip).and_return('4.3.2.1')

    @user = users(:jrice)
    @data_objects = DataObject.find :all, :limit => 5

    # assign agents to all of the data objects ... the fixtures don't seem to work for this anymore?
    @an_agent = Agent.find :first
    @data_objects.each do |o|
      begin
        AgentsDataObject.create :agent => @an_agent, :data_object => o, :view_order => 0, :agent_role_id => 2
      rescue
        # eat ActiveRecord::StatementInvalid Mysql::Error's
      end
    end

    @data_object_log_params = {
      :user_id => @user.id,
      :user_agent => @request.user_agent,
      :ip_address_raw => IpAddress.ip2int('4.3.2.1'),
      :data_object => @data_objects.first,
      :data_type => @data_objects.first.data_type
    }
    
    DataObjectLog.delete_all
  end

  it 'should log a data object if ' do
    one_object = @data_objects.shift

    DataObjectLog.data_logging_enabled = false
    lambda {
      DataObjectLog.log one_object, @request, @user
    }.should_not change(DataObjectLog, :count)
    DataObjectLog.find(:first).should be_nil

    DataObjectLog.data_logging_enabled = true
    lambda {
      DataObjectLog.log one_object, @request, @user
    }.should change(DataObjectLog, :count).by(1)
      
    DataObjectLog.data_logging_enabled = false
    lambda {
      DataObjectLog.log @data_objects, @request, @user
    }.should_not change(DataObjectLog, :count)
      
    DataObjectLog.data_logging_enabled = true
    lambda {
      DataObjectLog.log @data_objects, @request, @user
    }.should change(DataObjectLog, :count).by(7) # changing the fixtures changes this  :(
  end

  # worthy of integration test?
  #
  # we should hit a page as a logged in User and confirm that the
  # DataObjects on the page get logged
  it 'should log the User who viewed a DataObject'
  
  it 'should require IP Address, User Agent, and DataObject(s)' do
    DataObjectLog.new(@data_object_log_params).should be_valid

    [ :ip_address_raw, :user_agent, :data_object ].each do |param|
      DataObjectLog.create(@data_object_log_params.merge(param => nil)).should have_at_least(1).errors_on(param)
    end
  end

  it 'should not require a DataType (derived from DataObject)' do
    lambda {
      log = DataObjectLog.create(@data_object_log_params.merge( :data_type => nil ))
      log.data_type.should_not be_nil
      log.data_type.should == log.data_object.data_type
    }.should change(DataObjectLog, :count).by(1)
  end

  it 'should have access to a User and a DataObject' do
    lambda {
      DataObjectLog.log @data_objects, @request, @user
    }.should change(DataObjectLog, :count).by(9) # changing the fixtures changes this  :(
      
    first = DataObjectLog.find(:first)
    first.user.should == @user
    first.data_object.should == @data_objects.first
    first.data_type.should == @data_objects.first.data_type
    first.user_agent.should == @request.user_agent
  end

end
