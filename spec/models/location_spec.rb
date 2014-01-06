require 'spec_helper'

describe Location do

  let(:model){ Location.new({:location => 'Woods Hole, MA 02543'}) }
  it_behaves_like "ActiveModel"

end
