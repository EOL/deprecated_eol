require File.dirname(__FILE__) + '/../spec_helper'

describe DataType do

  it '#create_valid should be valid' do
    DataType.create_valid.should be_valid
  end

end
# == Schema Info
# Schema version: 20081020144900
#
# Table name: data_types
#
#  id           :integer(2)      not null, primary key
#  label        :string(255)     not null
#  schema_value :string(255)     not null

