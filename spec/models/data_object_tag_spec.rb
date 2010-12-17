require File.dirname(__FILE__) + '/../spec_helper'

describe DataObjectTag do

  it { should validate_presence_of(:key) }
  it { should validate_presence_of(:value) }
  it { should validate_uniqueness_of(:value) }

  it 'should require a unique key / value pair' do
    Factory(:data_object_tag, :key => 'foo', :value => 'w00t' ).should be_valid
    Factory.build(:data_object_tag, :key => 'foo', :value => 'w00t' ).should_not be_valid
    Factory.build(:data_object_tag, :key => 'foo', :value => 'w00t-2' ).should be_valid
  end

end
