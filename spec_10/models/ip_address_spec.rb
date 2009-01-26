require File.dirname(__FILE__) + '/../spec_helper'

describe IpAddress do

  it '#create_valid should be valid' do
    IpAddress.create_valid!.should be_valid
  end

end
