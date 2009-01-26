require File.dirname(__FILE__) + '/../spec_helper'

describe CuratorActivity do

  before do
    CuratorActivity.delete_all # incase there are fixtures
  end
  
  it '#create_valid should be valid' do
    lambda { CuratorActivity.create_valid!.should be_valid }.should change(CuratorActivity, :count).by(1)
  end

  it 'should require a unique code' do
    CuratorActivity.new_valid( :code => nil ).should_not be_valid
    CuratorActivity.create_valid( :code => 'foo' ).should be_valid
    CuratorActivity.create_valid( :code => 'foo' ).should_not be_valid
    CuratorActivity.create_valid( :code => 'bar' ).should be_valid
  end
  
  it 'should provide shortcuts for often used codes' do
    lambda { CuratorActivity.approve }.should raise_error(ActiveRecord::RecordNotFound)
    activity = CuratorActivity.approve! # ! does find_or_create
    CuratorActivity.approve!.should == activity
    CuratorActivity.blah!.code.should == 'blah'
  end
    
end
