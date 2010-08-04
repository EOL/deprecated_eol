require 'spec_helper'

describe UserInfo do
  before(:each) do
    @valid_attributes = {
      :user => ,
      :areas_of_interest => "value for areas_of_interest",
      :heard_of_eol => "value for heard_of_eol",
      :interested_in_contributing => false,
      :interested_in_curating => false,
      :interested_in_advisory_forum => false,
      :show_information => false,
      :age_range => "value for age_range"
    }
  end

  it "should create a new instance given valid attributes" do
    UserInfo.create!(@valid_attributes)
  end
end
