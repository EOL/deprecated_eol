require File.dirname(__FILE__) + '/../spec_helper'

describe Language do

  it '#create_valid should be valid' do
    Language.create_valid.should be_valid
  end

end
# == Schema Info
# Schema version: 20081020144900
#
# Table name: languages
#
#  id           :integer(2)      not null, primary key
#  iso_639_1    :string(6)       not null
#  iso_639_2    :string(6)       not null
#  iso_639_3    :string(6)       not null
#  label        :string(100)     not null
#  name         :string(100)     not null
#  sort_order   :integer(1)      not null, default(1)
#  source_form  :string(100)     not null
#  activated_on :timestamp

