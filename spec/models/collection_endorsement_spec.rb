require File.dirname(__FILE__) + '/../spec_helper'

describe CollectionEndorsement do

  before(:all) do
    load_foundation_cache # Needs too much stuff... English, default roles, feed item types, etc...
    @community = Community.gen
    @good_collection = Collection.gen
    @bad_collection = Collection.gen
    @accepted_request = @good_collection.request_endorsement_from_community(@community)
    @pending_request = @bad_collection.request_endorsement_from_community(@community)
    @admin = User.gen
    @user = User.gen
    @community_admin = @community.initialize_as_created_by(@admin)
    @community_member = @user.join_community(@community)
  end

  before(:each) do
    # Reset the endorsements to make sure they are right:
    @accepted_request.update_attribute(:member_id, @community_admin.id)
    @pending_request.update_attribute(:member_id, nil)
  end

  it 'should fail if there is no collection specified' do
    ce = CollectionEndorsement.new
    ce.member_id = @community_admin.id
    ce.community_id = @community.id
    ce.save
    ce.valid?.should_not be_true
  end


  it 'should fail if there is no community specified' do
    ce = CollectionEndorsement.new
    ce.member_id = @community_admin.id
    ce.collection_id = @good_collection.id
    ce.save
    ce.valid?.should_not be_true
  end

  it 'should know if it is endorsed' do
    @accepted_request.endorsed?.should be_true
    @pending_request.endorsed?.should_not be_true
  end

  it 'should know if it is pending' do
    @pending_request.pending?.should be_true
    @accepted_request.pending?.should_not be_true
  end

  it 'should be endorsable by a member with privs' do
    @pending_request.endorsed_by(@community_admin)
    @pending_request.reload # just to be sure.
    @pending_request.endorsed?.should be_true
  end

  it 'should NOT be endorsable by a member without privs' do
    lambda { @pending_request.endorsed_by(@community_member) }.should raise_error
    @pending_request.reload # just to be sure.
    @pending_request.endorsed?.should_not be_true
  end

end
