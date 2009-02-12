require File.dirname(__FILE__) + '/../spec_helper'

describe Name do

  it { should belong_to(:canonical_form) }
  it { should validate_presence_of(:string) }
  it { should validate_presence_of(:italicized) }
  it { should validate_presence_of(:canonical_form) }

  it "should require a valid #string" do
    Name.gen( :string => 'Tiger' ).should be_valid
    Name.build( :string => 'Tiger' ).should_not be_valid # because there's already a Tiger
  end

end
