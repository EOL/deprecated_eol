require File.dirname(__FILE__) + '/../spec_helper'

describe MimeType do

  it '#create_valid should be valid' do
    MimeType.create_valid.should be_valid
  end

end
# == Schema Info
# Schema version: 20081020144900
#
# Table name: mime_types
#
#  id    :integer(2)      not null, primary key
#  label :string(255)     not null

