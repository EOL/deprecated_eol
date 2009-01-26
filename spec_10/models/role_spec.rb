require File.dirname(__FILE__) + '/../spec_helper'

describe Role do

  before :all do
    @role_count = Role.count
  end

  it '#create_valid should be valid' do
    Role.create_valid.should be_valid
  end

  it 'should increment the Role count on #create (only in this example)' do
    lambda { Role.create_valid }.should change(Role,:count).from(@role_count).to(@role_count + 1)
  end

  # we need 2 examples to confirm that the count doesn't change between examples
  it 'should *still* increment the Role count on #create (only in this example)' do
    lambda { Role.create_valid }.should change(Role,:count).from(@role_count).to(@role_count + 1)
  end

end
# == Schema Info
# Schema version: 20081020144900
#
# Table name: roles
#
#  id         :integer(4)      not null, primary key
#  title      :string(255)
#  created_at :datetime
#  updated_at :datetime

