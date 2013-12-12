require File.dirname(__FILE__) + '/../spec_helper'

describe OpenAuthentication do

  before :all do
    @open_authentication_params = { guid: 'open_authentication_model_spec',
                                    provider: 'facebook',
                                    user_id: 1 }
    unless (@open_authentication = OpenAuthentication.find_by_guid(@open_authentication_params[:guid])) &&
           (@user = User.find_by_username('open_authentication_model_spec'))
      truncate_all_tables
      CuratorLevel.create_enumerated
      @user = User.gen(username: 'open_authentication_model_spec')
      @open_authentication = OpenAuthentication.new(@open_authentication_params.merge(user_id: @user.id))
      @open_authentication.save
    end
  end

  describe '#validates_presence_of' do
    it 'should add error and prevent save if guid, provider or user_id (update only) are missing' do
      open_authentication = OpenAuthentication.new()
      open_authentication.save.should be_false
      open_authentication.should have(1).error_on(:guid)
      open_authentication.should have(1).error_on(:provider)
      @open_authentication.update_attributes(user_id: nil).should be_false
      @open_authentication.should have(1).error_on(:user_id)
    end
  end

  describe '#validates_uniqueness_of' do
    it 'should add error and prevent save if user already has a linked account from that provider' do
      open_authentication = OpenAuthentication.create(@open_authentication_params.merge({guid: 'abcde'}))
      open_authentication = OpenAuthentication.new(@open_authentication_params.merge({guid: 'abcde'}))
      open_authentication.save.should be_false
      open_authentication.errors[:user_id].first.should =~ /^only one account from each third-party provider/
    end
    it 'should add error and prevent save if the guid and provider are already linked to a user' do
      open_authentication = OpenAuthentication.new(@open_authentication_params.merge({user_id: @user.id + 1}))
      open_authentication.save.should be_false
      open_authentication.should have(1).error_on(:guid)
      open_authentication.errors[:guid].first.should =~ /^the third-party account is already connected/
    end
  end

  describe '#verified?' do
    it 'should know if an authentication has a verified_at time' do
      @open_authentication.update_column(:verified_at, Time.now).should be_true
      @open_authentication.verified?.should be_true
      @open_authentication.update_column(:verified_at, nil).should be_true
      @open_authentication.verified?.should be_false
    end
  end

  describe '#connection_established' do
    it 'should update verified_at to Time' do
      @open_authentication.update_column(:verified_at, nil).should be_true
      @open_authentication.verified_at.should be_nil
      @open_authentication.user = @user # This seems to be getting lost, somehow.
      @open_authentication.connection_established
      @open_authentication.verified_at.should be_a(Time)
    end

    it 'should raise EOL::Exceptions::OpenAuthMissingConnectedUser if user is nil' do
      user = User.last
      @open_authentication.update_column(:user_id, user.id + 1)
      lambda { @open_authentication.connection_established }.should
        raise_error(EOL::Exceptions::OpenAuthMissingConnectedUser)
    end
  end

  describe '#connection_not_established' do
    it 'should update verified_at to nil' do
      @open_authentication.update_column(:verified_at, Time.now).should be_true
      @open_authentication.verified_at.should be_a(Time)
      @open_authentication.connection_not_established
      @open_authentication.verified_at.should be_nil
    end
  end

  describe '#can_be_deleted_by?' do
    it 'should know whether a user DOESN\'T have access to delete an open authentication' do
      @open_authentication.update_column(:user_id, @user.id + 1).should be_true
      @open_authentication.can_be_deleted_by?(@user).should be_false
    end

    it 'should know when a user can delete open authentication' do
      begin
        @open_authentication.update_column(:user_id, @user.id)
      rescue
        @open_authentication = OpenAuthentication.where(user_id: 1, provider: 'facebook').first
      end
      @open_authentication.can_be_deleted_by?(@user).should be_true
    end
  end

end

