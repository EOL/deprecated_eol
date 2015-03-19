require 'spec_helper'

describe InstitutionalSponsor do
  
  before :all do
    InstitutionalSponsor.gen(active: true)
    InstitutionalSponsor.gen(active: true)
    InstitutionalSponsor.gen(active: false)
  end
  
  it 'should get active sponsors only' do
    expect(InstitutionalSponsor.active.length).to eq(2)
  end
  
  it 'should take less than or equal nummber of active sponsors' do
    expect(InstitutionalSponsor.get_active_sponsors_with_limit.length).to be <= $SPONSORS_ON_HOME_PAGE
  end
end
