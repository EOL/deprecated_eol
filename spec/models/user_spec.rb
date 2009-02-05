require File.dirname(__FILE__) + '/../spec_helper'

describe User do

  # scenario :foundation # <--- why are we using scenarios in a model spec ? 
  #                             we should try to minimize the data dependencies 
  #                             of our models.  black box specs need to run the 
  #                             *whole* stack so they might require *some* data.
  #
  #                             model specs shouldn't require much besides the model class!

  # There are lots, LOTS more of these to do, I'm just keeping these here for examples:
  it { should validate_presence_of(:given_name) }
  it { should validate_uniqueness_of(:username) }
  it { should validate_confirmation_of(:entered_password) }

  it 'should be a curator (of the appropriate clade only) after approve_to_curate!' do
    Role.gen :title => 'Curator'

    bad_clade = Factory(:hierarchy_entry)
    clade     = Factory(:hierarchy_entry) 
    user      = Factory(:user)
    user.approve_to_curate! clade
    user.should be_a_curator_of(clade)
    user.should_not be_a_curator_of(bad_clade)
  end

end
