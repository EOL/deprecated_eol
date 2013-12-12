require 'spec_helper'

describe UserPrimaryRole do
  before(:each) do
    @string = 'aaa'
    @valid_attributes = {
      name: @string.succ
    }
  end

  it "should create a new instance given valid attributes" do
    UserPrimaryRole.create!(@valid_attributes)
  end
end
