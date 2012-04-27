require File.dirname(__FILE__) + '/../spec_helper'

describe UsersController do

  before(:all) do
    unless @user = User.find_by_username('users_controller_spec')
      truncate_all_tables
      Language.create_english
      SpecialCollection.gen(:name => 'Watch')
      CuratorLevel.create_defaults
      UserIdentity.create_defaults
      @user = User.gen(:username => 'users_controller_spec')
      cot = ChangeableObjectType.gen(:ch_object_type => 'synonym')
    end
  end

  describe 'GET new' do
    it 'should render new unless logged in' do
      get :new
      response.rendered[:template].should == 'users/new.html.haml'
      response.redirected_to.should be_blank
      assigns[:user].open_authentications.should be_blank
      get :new, nil, { :user => @user, :user_id => @user.id }
      response.rendered[:template].should_not == 'users/new.html.haml'
      response.redirected_to.should == @user
    end

    context 'extended for open authentication' do
      before :each do
        stub_oauth_requests
      end

      it 'should clear session data when user cancels sign up at confirmation page' do
        get :new, nil, {:oauth_token_yahoo_1234 => 'atoken', :oauth_secret_yahoo_1234 => 'asecret'}
        session[:oauth_token_yahoo_1234].should be_nil
        session[:oauth_secret_yahoo_1234].should be_nil
      end

      it 'should render confirmation page when user signs up with Facebook' do
        params_data, session_data = oauth_request_data(:facebook, 2)
        get :new, params_data, session_data
        assigns[:open_auth].should be_a(EOL::OpenAuth::Facebook)
        assigns[:user].new_record?.should be_true
        assigns[:user].open_authentications.first.provider.should == 'facebook'
        assigns[:user].open_authentications.first.guid.should == 'facebookuserguid'
        assigns[:user].open_authentications.length.should == 1
        assigns[:user].given_name.should == 'FacebookGiven'
        assigns[:user].family_name.should == 'FacebookFamily'
      end

      it 'should redirect to new user URL and flash error if user denies access during OAuth1 sign up' do
        oauth1_consumer = OAuth::Consumer.new("key", "secret", {
          :site => "http://fake.oauth1.provider",
          :request_token_path => "/example/request_token",
          :access_token_path => "/example/access_token_denied",
          :authorize_path => "/example/authorize" })
        OAuth::Consumer.should_receive(:new).and_return(oauth1_consumer)
        get :new, {:denied => "key",
                   :oauth_provider => 'twitter'},
                  { "twitter_request_token_token" => 'key',
                    "twitter_request_token_secret" => 'secret' }
        assigns[:open_auth].should be_a(EOL::OpenAuth::Twitter)
        response.redirected_to.should == new_user_url
        flash[:error].should match /Sorry, we are not authorized.+?Twitter/
      end
    end
  end

  describe 'POST create' do
    context 'extended for open authentication' do
      it 'should redirect to authorize uri when log in is with Facebook' do
        post :create, { :oauth_provider => 'facebook' }
        response.redirected_to.should =~ /^https:\/\/graph.facebook.com\/oauth\/authorize/
      end
      it 'should redirect to authorize uri when log in is with Google' do
        post :create, { :oauth_provider => 'google' }
        response.redirected_to.should =~ /^https:\/\/accounts.google.com\/o\/oauth2\/auth/
      end
      it 'should redirect to authorize uri when log in is with Twitter' do
        stub_oauth_requests
        post :create, { :oauth_provider => 'twitter' }
        response.redirected_to.should =~ /http:\/\/api.twitter.com\/oauth\/authenticate/
      end
      it 'should redirect to authorize uri when log in is with Yahoo' do
        stub_oauth_requests
        post :create, { :oauth_provider => 'yahoo' }
        response.redirected_to.should =~ /https:\/\/api.login.yahoo.com\/oauth\/v2\/request_auth/
      end

      it 'should create a new EOL account connected to a Facebook account, send welcome email and log in user'
      it 'should create a new EOL account connected to a Google account, send welcome email and log in user'
      it 'should create a new EOL account connected to a Twitter account, send welcome email and log in user'
      it 'should create a new EOL account connected to a Yahoo! account, send welcome email and log in user'
      it 'should not create an EOL account is third-party account is already connected to an EOL user'
    end

    it 'should create a new EOL user and send verification email if registration is valid'
    it 'should not create a new user if registration is invalid'
  end

  describe 'GET show' do
    it 'should render show' do
      get :show, { :id => @user.id }
      assigns[:user].should == @user
      response.rendered[:template].should == 'users/show.html.haml'
    end
  end

  describe 'GET edit' do
    it 'should raise error if edit before log in' do
      lambda { get :edit, { :id => @user.id } }.should raise_error(EOL::Exceptions::SecurityViolation)
    end
    it 'should raise security violation if edit wrong user' do
      user = User.gen
      session[:user_id] = @user.id
      lambda { get :edit, { :id => user.id } }.should raise_error(EOL::Exceptions::SecurityViolation)
    end
    it 'should render edit properly if editing self' do
      get :edit, { :id => @user.id }, { :user => @user, :user_id => @user.id }
      assigns[:user].should == @user
      response.rendered[:template].should == 'users/edit.html.haml'
      response.redirected_to.should be_blank
    end
  end

  describe 'PUT update' do

    it 'should raise error if not logged in' do
      hashed_password = User.find(@user).hashed_password
      expect{ put :update, { :id => @user.id, :user => { :id => @user.id, :entered_password => 'newpassword', :entered_password_confirmation => 'newpassword' } } }.should raise_error(EOL::Exceptions::SecurityViolation)
    end
    it 'should update and render show if updating self' do
      hashed_password = User.find(@user).hashed_password
      session[:user_id] = @user.id
      User.find(@user).hashed_password.should == hashed_password
      put :update, { :id => @user.id, :user => { :id => @user.id, :entered_password => 'newpassword', :entered_password_confirmation => 'newpassword' } }
      user = User.find(@user)
      user.hashed_password.should_not == hashed_password
      user.hashed_password.should == User.hash_password('newpassword')
      response.redirected_to.should == @user
    end

    it 'should render edit on validation errors' do
      hashed_password = User.find(@user).hashed_password
      session[:user_id] = @user.id
      put :update, { :id => @user.id, :user => { :id => @user.id, :entered_password => 'abc', :entered_password_confirmation => 'abc' } }
      User.find(@user).hashed_password.should == hashed_password
      response.rendered[:template].should == 'users/edit.html.haml'
    end

    it 'should ignore entered passwords when password confirmation is blank and entered password is same as existing password' do # i.e. passwords auto filled by browser
      user = User.gen(:password => 'secret')
      hashed_password = user.hashed_password
      username = user.username
      bio = user.bio
      put :update, { :id => user.id, :user => { :id => user.id, :entered_password => 'secret', :entered_password_confirmation => '',
                                                :username => 'myusername', :bio => 'My bio' } },
                   { :user => user, :user_id => user.id }
      user = User.find(user)
      user.hashed_password.should == hashed_password
      user.username.should_not == username
      user.username.should == 'myusername'
      user.bio.should_not == bio
      user.bio.should == 'My bio'
    end

    it 'should render curation privileges on validation errors for curator application' do
      user = User.gen
      put :update, { :id => user.id, :commit_curation_privileges_put => 'Curation application',
                     :user => { :id => user.id, :username => user.username, :credentials => '',
                                :requested_curator_level_id => CuratorLevel.master_curator.id } },
                   { :user => user, :user_id => user.id }
      response.rendered[:template].should == 'users/curation_privileges.html.haml'
      assigns[:user].errors.any?.should be_true
    end

    it 'should allow instant approval for assistant curators without requirements' do
      user = User.gen
      put :update, { :id => user.id, :commit_curation_privileges_put => 'Curation application',
                     :user => { :id => user.id, :username => user.username, :credentials => '',
                                :requested_curator_level_id => CuratorLevel.assistant_curator.id } },
                   { :user => user, :user_id => user.id }
      assigns[:user].errors.any?.should be_false
      assigns[:user].curator_level_id.should == CuratorLevel.assistant_curator.id
    end
  end

  describe 'GET curation_privileges' do
    it 'should raise error when not logged in' do
      expect{ get :curation_privileges, { :id => @user.id } }.should raise_error(EOL::Exceptions::SecurityViolation)
    end
    it 'should render curation privileges only if applying for self' do
      user = User.gen
      session[:user_id] = @user.id
      lambda { get :curation_privileges, { :id => user.id } }.should raise_error(EOL::Exceptions::SecurityViolation)
    end
    it 'should render curation privileges properly' do
      user = User.gen
      session[:user_id] = @user.id
      get :curation_privileges, { :id => @user.id }
      assigns[:user].should == @user
      response.rendered[:template].should == 'users/curation_privileges.html.haml'
      response.redirected_to.should be_blank
    end
  end

  describe 'GET verify' do
    it 'should not activate already active user' do
      active_user = User.gen(:active => true, :validation_code => User.generate_key)
      Notifier.should_not_receive(:deliver_user_activated)
      Notifier.should_not_receive(:deliver_user_verification)
      get :verify, { :user_id => active_user.id, :validation_code => active_user.validation_code }
      response.redirected_to.should == login_path
    end
    it 'should activate inactive user with valid verification code' do
      user = User.gen(:active => false, :validation_code => User.generate_key)
      Notifier.should_receive(:deliver_user_activated).once.with(user)
      get :verify, { :user_id => user.id, :validation_code => user.validation_code }
      user.reload
      user.active.should be_true
      response.redirected_to.should == activated_user_path(user)
    end
    it 'should not activate user with invalid verification code' do
      inactive_user = User.gen(:active => false, :validation_code => User.generate_key)
      Notifier.should_not_receive(:deliver_user_activated)
      Notifier.should_receive(:deliver_user_verification).once.with(inactive_user, verify_user_url(inactive_user.id, inactive_user.validation_code))
      get :verify, { :user_id => inactive_user.id, :validation_code => 'invalidverificationcode123' }
      response.redirected_to.should == pending_user_path(inactive_user)
    end
    it 'should ignore validation errors on user model' do
      user = User.gen(:active => false, :validation_code => User.generate_key)
      user.update_attribute(:agreed_with_terms, false)
      user.errors.on(:agreed_with_terms).should == 'must be accepted'
      user.active?.should be_false
      get :verify, { :user_id => user.id, :validation_code => user.validation_code }
      user.reload
      user.active.should be_true
      response.redirected_to.should == activated_user_path(user)
    end
  end

  describe 'GET pending' do
    it 'should render pending' do
      get :pending, { :id => @user.id }
      assigns[:user].should == @user
      response.rendered[:template].should == 'users/pending.html.haml'
    end
  end

  describe 'GET activated' do
    it 'should render activated' do
      get :activated, { :id => @user.id }
      assigns[:user].should == @user
      response.rendered[:template].should == 'users/activated.html.haml'
    end
  end

  describe 'GET terms_agreement' do

    before(:each) do
      @disagreeable_user = User.gen
      @disagreeable_user.agreed_with_terms = 0
      @disagreeable_user.save(false)
    end

    it 'should render terms agreement' do
      User.find(@disagreeable_user).agreed_with_terms.should be_false
      TranslatedContentPage.gen(:content_page => ContentPage.gen(:page_name => 'terms_of_use'),
                                :active_translation => 1,
                                :language => Language.english)
      get :terms_agreement, { :id => @disagreeable_user.id }, { :user => @disagreeable_user, :user_id => @disagreeable_user.id }
      assigns[:user].should == @disagreeable_user
      assigns[:terms].should be_a(TranslatedContentPage)
      response.rendered[:template].should == 'users/terms_agreement.html.haml'
    end

    it 'should force users to agree to terms before viewing other pages' do
      User.find(@disagreeable_user).agreed_with_terms.should be_false
      get :show, { :id => @disagreeable_user.id }, { :user => @disagreeable_user, :user_id => @disagreeable_user.id }
      response.redirected_to.should == terms_agreement_user_path(@disagreeable_user)
      get :edit, { :id => @disagreeable_user.id }, { :user => @disagreeable_user, :user_id => @disagreeable_user.id }
      response.redirected_to.should == terms_agreement_user_path(@disagreeable_user)
    end

    it 'should not allow users to render terms for another user' do
      User.find(@disagreeable_user).agreed_with_terms.should be_false
      expect{ get :terms_agreement, { :id => @disagreeable_user.id } }.should raise_error(EOL::Exceptions::SecurityViolation) # anonymous user trying to access user terms
      expect{ get :terms_agreement, { :id => @disagreeable_user.id }, { :user => @user, :user_id => @user.id } }.should raise_error(EOL::Exceptions::SecurityViolation)
    end
  end

  describe 'POST terms_agreement' do
    before(:each) do
      @disagreeable_user = User.gen
      @disagreeable_user.agreed_with_terms = 0
      @disagreeable_user.save(false)
    end
    it 'should allow the current user to agree to terms' do
      User.find(@disagreeable_user).agreed_with_terms.should be_false
      post :terms_agreement, { :id => @disagreeable_user.id, :commit_agreed => 'I Agree' }, { :user => @disagreeable_user, :user_id => @disagreeable_user.id }
      User.find(@disagreeable_user).agreed_with_terms.should be_true
      response.redirected_to.should == user_url(@disagreeable_user)
    end

    it 'should not allow users to agree to terms for another user' do
      User.find(@disagreeable_user).agreed_with_terms.should be_false
      expect{ post :terms_agreement, { :id => @disagreeable_user.id } }.should raise_error(EOL::Exceptions::SecurityViolation)
      User.find(@disagreeable_user).agreed_with_terms.should be_false
      expect{ post :terms_agreement, { :id => @disagreeable_user.id }, { :user => @user, :user_id => @user.id } }.should raise_error(EOL::Exceptions::SecurityViolation)
      User.find(@disagreeable_user).agreed_with_terms.should be_false
    end
  end

  describe 'GET recover account' do
    it 'should render recover account unless logged in' do
      get :recover_account
      response.rendered[:template].should == 'users/recover_account.html.haml'
      response.redirected_to.should be_blank
      get :recover_account, nil, { :user => @user, :user_id => @user.id }
      response.rendered[:template].should_not == 'users/recover_account.html.haml'
      response.redirected_to.should == @user
    end
  end

  describe 'POST recover account' do
    before :all do
      unless @recover_user = User.find_by_username('recover_account_spec')
        @recover_user = User.gen(:username => 'recover_account_spec', :email => 'unique@address.com')
      end
    end

    it "should find user by email or flash error if it can't find user by email" do
      post :recover_account
      assigns[:users].should be_blank
      response.rendered[:template].should == 'users/recover_account.html.haml'
      flash[:error].should_not be_blank
      response.redirected_to.should be_blank
      post :recover_account, { :user => { :email => '' } }
      assigns[:users].should be_blank
      response.rendered[:template].should == 'users/recover_account.html.haml'
      flash[:error].should_not be_blank
      response.redirected_to.should be_blank
      post :recover_account, { :user => { :email => 'userdoesnotexist' } }
      assigns[:users].should be_blank
      response.rendered[:template].should == 'users/recover_account.html.haml'
      flash[:error].should_not be_blank
      response.redirected_to.should be_blank
    end
    it 'should raise exception if user is hidden' do
      @recover_user.update_attribute(:hidden, true)
      @recover_user.hidden.should be_true
      expect{ post :recover_account, :user => { :email => @recover_user.email } }.
        should raise_error(EOL::Exceptions::SecurityViolation)
      @recover_user.update_attribute(:hidden, false)
    end
    it 'should give user a new recover account token and send recover account email' do
      Notifier.should_receive(:deliver_user_recover_account).
        with(@recover_user, /users\/#{@recover_user.id}\/temporary_login\/[a-f0-9]{40}$/i)
      post :recover_account, :user => { :email => @recover_user.email }
      @recover_user.reload!
      @recover_user.recover_account_token.should =~ /^[0-9a-f]{40}$/i
      response.redirected_to.should == login_url
      flash[:notice].should =~ /further instructions/i
    end
    it 'should render choose account first if multiple accounts found' do
      shared_email_address = 'fake@email.com'
      user1 = User.gen(:email => shared_email_address)
      user2 = User.gen(:email => shared_email_address)
      user3 = User.gen(:email => shared_email_address)
      post :recover_account, :user => {:email => shared_email_address}
      assigns[:users].size.should == 3
      assigns[:users].all?{|u| u.password_reset_token.blank? }.should be_true
      response.rendered[:template].should == 'users/recover_account_choose_account.html.haml'
      Notifier.should_receive(:deliver_user_recover_account).
        with(user1, /users\/#{user1.id}\/temporary_login\/[a-f0-9]{40}$/i)
      post :recover_account, :user => {:email => shared_email_address, :id => user1.id}
      user1.reload!
      user1.recover_account_token.should =~ /^[0-9a-f]{40}$/i
      response.redirected_to.should == login_url
      flash[:notice].should =~ /further instructions/i
    end
    it 'should ignore validation errors on user model' do
      @recover_user.update_attribute(:agreed_with_terms, false)
      @recover_user.errors.on(:agreed_with_terms).should == 'must be accepted'
      Notifier.should_receive(:deliver_user_recover_account).
        with(@recover_user, /users\/#{@recover_user.id}\/temporary_login\/[a-f0-9]{40}$/i)
      post :recover_account, :user => { :email => @recover_user.email }
      @recover_user.reload!
      @recover_user.recover_account_token.should =~ /^[0-9a-f]{40}$/i
      response.redirected_to.should == login_url
      flash[:notice].should =~ /further instructions/i
      @recover_user.update_attribute(:agreed_with_terms, true)
    end

  end

  describe 'GET temporary_login' do
    it 'should log in users with valid token' do
      user = User.gen(:recover_account_token => User.generate_key,
                      :recover_account_token_expires_at => 24.hours.from_now)
      get :temporary_login, :user_id => user.id, :recover_account_token => user.recover_account_token
      response.redirected_to.should == edit_user_path(user)
      user.reload
      user.recover_account_token.should be_nil
      user.recover_account_token_expires_at.should be_nil
      session[:user_id].should == user.id
    end
    it 'should not log in hidden users'
    it 'should not log in users with invalid token' do
      user = User.gen(:recover_account_token => User.generate_key,
                      :recover_account_token_expires_at => 24.hours.from_now)
      get :temporary_login, :user_id => user.id, :recover_account_token => 'invalidtoken'
      session[:user_id].should_not == user.id
      response.redirected_to.should == recover_account_users_path
    end
    it 'should not log in users with expired token' do
      user = User.gen(:recover_account_token => User.generate_key,
                      :recover_account_token_expires_at => 24.hours.ago)
      get :temporary_login, :user_id => user.id, :recover_account_token => user.recover_account_token
      session[:user_id].should_not == user.id
      response.redirected_to.should == recover_account_users_path
    end
  end
end
