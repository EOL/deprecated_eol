require 'spec_helper'

describe Location do

  let(:model){ Location.new({:location => 'Woods Hole, MA, USA'}) }

  it_behaves_like "ActiveModel"

  it 'is invalid if latitude is not a number'
  it 'is invalid if longitude is not a number'


end
