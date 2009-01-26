require File.dirname(__FILE__) + '/../spec_helper'

describe License do

  it '#create_valid should be valid' do
    License.create_valid.should be_valid
  end

end
# == Schema Info
# Schema version: 20081020144900
#
# Table name: licenses
#
#  id          :integer(2)      not null, primary key
#  description :string(400)     not null
#  logo_url    :string(255)     not null
#  source_url  :string(255)     not null
#  title       :string(255)     not null
#  version     :string(6)       not null

