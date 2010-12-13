require 'spec_helper'

describe Privilege do
  before(:each) do
    @valid_attributes = {
      :name => "value for name",
      :sym => "value for sym",
      :level => 1,
      :type => "value for type"
    }
  end

  it "should create a new instance given valid attributes" do
    Privilege.create!(@valid_attributes)
  end
end
