require File.dirname(__FILE__) + '/../spec_helper'

describe Name do

  it { should belong_to(:canonical_form) }
  it { should validate_presence_of(:string) }
  it { should validate_presence_of(:italicized) }
  it { should validate_presence_of(:canonical_form) }

end
