require File.dirname(__FILE__) + '/../spec_helper'

describe OpenAuthentication do

  before :all do
    @open_authentication_params = { :guid => 'open_authentication_model_spec',
                                    :provider => 'facebook',
                                    :user_id => 1 }
    unless @open_authentication = OpenAuthentication.find_by_guid(@open_authentication_params[:guid])
      truncate_all_tables
      @open_authentication = OpenAuthentication.new(@open_authentication_params)
      @open_authentication.save
    end
  end

  describe '#validates_presence_of' do
    it 'should add error and prevent save if guid, provider or user_id are missing' do
      open_authentication = OpenAuthentication.new()
      open_authentication.save.should be_false
      open_authentication.errors.count.should == 3
      open_authentication.should have(1).error_on(:guid)
      open_authentication.should have(1).error_on(:provider)
      open_authentication.should have(1).error_on(:user_id)
    end
  end

  describe '#validates_uniqueness_of' do

    it 'should add error and prevent save if user already has a linked account from that provider' do
      open_authentication = OpenAuthentication.new(@open_authentication_params.merge({:guid => 'abcde'}))
      open_authentication.save.should be_false
      open_authentication.errors.count.should == 1
      open_authentication.should have(1).error_on(:user_id)
      open_authentication.errors[:user_id].should match /^only one account from each third-party provider/
    end

    it 'should add error and prevent save if the guid and provider are already linked to a user' do
      open_authentication = OpenAuthentication.new(@open_authentication_params.merge({:user_id => 2}))
      open_authentication.save.should be_false
      open_authentication.errors.count.should == 1
      open_authentication.should have(1).error_on(:guid)
      open_authentication.errors[:guid].should match /^the third-party account is already connected/
    end

  end

  describe '#verified?' do
    it 'should know if an authentication has a verified_at time' do
      @open_authentication.update_attributes(:verified_at => Time.now).should be_true
      @open_authentication.verified?.should be_true
      @open_authentication.update_attributes(:verified_at => nil).should be_true
      @open_authentication.verified?.should be_false
    end
  end

  describe '#verified' do
    it 'should update verified_at to Time when authentication is verified' do
      @open_authentication.update_attributes(:verified_at => nil)
      @open_authentication.verified_at.should be_nil
      @open_authentication.verified
      @open_authentication.verified_at.should be_a(Time)
    end
  end

  describe '#not_verified' do
    it 'should update verified_at to nil when authentication is unverified' do
      @open_authentication.update_attributes(:verified_at => Time.now)
      @open_authentication.verified_at.should be_a(Time)
      @open_authentication.not_verified
      @open_authentication.verified_at.should be_nil
    end
  end

  describe '#self.existing_authentication' do
    it 'should know if a third-party authentication account is already linked to a user' do
      OpenAuthentication.existing_authentication(@open_authentication.provider,
                                                 @open_authentication.guid).should be_true
    end

    it 'should know if a third-party authentication account is not already linked to a user' do
      OpenAuthentication.existing_authentication('does not exist', 'does not exist').should be_false
    end
  end

end

