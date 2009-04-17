require File.dirname(__FILE__) + '/../spec_helper'

describe UsersDataObject do
  it { should validate_presence_of(:user_id)}
  it { should validate_presence_of(:data_object_id)}
  it { should validate_uniqueness_of(:data_object_id)}

end