require "spec_helper"

describe Member do

  before(:all) do
    load_foundation_cache
    @user = User.gen
    @community = Community.gen
    @member = Member.gen(user: @user, community: @community)
  end

  before(:each) do
    @member.save!
  end

  it 'should only be able to add a member to a community once' do
    m = Member.new(user_id: @user.id, community_id: @community.id)
    m.valid?.should_not be_true
  end

  # TODO - lots more based on admin

end
