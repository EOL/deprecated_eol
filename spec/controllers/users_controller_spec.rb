require File.dirname(__FILE__) + '/../spec_helper'

describe UsersController do

  before(:all) do
    truncate_all_tables
    Language.create_english
    SpecialCollection.gen(:name => 'Watch')
    CuratorLevel.create_defaults
    UserIdentity.create_defaults
    @user = User.gen
    cot = ChangeableObjectType.gen(:ch_object_type => 'synonym')
  end

  describe 'GET new' do
    it 'should render new unless logged in' do
      get :new
      response.rendered[:template].should == 'users/new.html.haml'
      response.redirected_to.should be_blank
      get :new, nil, { :user => @user, :user_id => @user.id }
      response.rendered[:template].should_not == 'users/new.html.haml'
      response.redirected_to.should == @user
    end
  end

  describe 'POST create' do
    it 'should rerender new on validation errors'
    it 'should redirect on success'
    it 'should send verify email notification'
    it 'should create agent record for a user during account creation'
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
      response.redirected_to.should == user_path(@disagreeable_user)
    end

    it 'should not allow users to agree to terms for another user' do
      User.find(@disagreeable_user).agreed_with_terms.should be_false
      expect{ post :terms_agreement, { :id => @disagreeable_user.id } }.should raise_error(EOL::Exceptions::SecurityViolation)
      User.find(@disagreeable_user).agreed_with_terms.should be_false
      expect{ post :terms_agreement, { :id => @disagreeable_user.id }, { :user => @user, :user_id => @user.id } }.should raise_error(EOL::Exceptions::SecurityViolation)
      User.find(@disagreeable_user).agreed_with_terms.should be_false
    end
  end

  describe 'GET forgot_password' do
    it 'should render forgot password unless logged in' do
      get :forgot_password
      response.rendered[:template].should == 'users/forgot_password.html.haml'
      response.redirected_to.should be_blank
      get :forgot_password, nil, { :user => @user, :user_id => @user.id }
      response.rendered[:template].should_not == 'users/forgot_password.html.haml'
      response.redirected_to.should == @user
    end
  end

  describe 'POST forgot_password' do
    it 'should find user or return error' do
      post :forgot_password, { :user => { :username_or_email => '' } }
      assigns[:user].should be_blank
      response.rendered[:template].should == 'users/forgot_password.html.haml'
      post :forgot_password, { :user => { :username_or_email => 'userdoesnotexist' } }
      assigns[:user].should be_blank
      response.rendered[:template].should == 'users/forgot_password.html.haml'
    end
    it 'should render choose user view if multiple users found' do
      user1 = User.gen(:email => 'johndoe@example.com')
      user2 = User.gen(:email => 'johndoe@example.com')
      user3 = User.gen(:email => 'johndoe@example.com')
      post :forgot_password, :user => {:username_or_email => user1.email}
      assigns[:users].size.should == 3
      assigns[:users].all?{|u| u.password_reset_token.blank? }.should be_true
      response.rendered[:template].should == 'users/forgot_password_choose_account.html.haml'
    end
    it 'should generate a reset password token and send email if single user found' do
      user1 = User.gen(:email => 'johndoe@example.com')
      user2 = User.gen(:email => 'johndoe@example.com')
      user3 = User.gen(:email => 'johndoe@example.com')
      Notifier.should_receive(:deliver_user_reset_password).with(user1, /users\/#{user1.id}\/reset_password\/[a-z0-9]*$/i)
      post :forgot_password, :user => {:username_or_email => user1.username}
      assigns[:users].size.should == 1
      assigns[:users][0].id.should == user1.id
      assigns[:users][0].password_reset_token.should_not be_blank
    end
  end

  describe 'GET reset_password' do
    it 'should log in users with valid reset password token' do
      user = User.gen(:password_reset_token => User.generate_key, :password_reset_token_expires_at => 24.hours.from_now)
      get :reset_password, :user_id => user.id, :password_reset_token => user.password_reset_token
      response.redirected_to.should == edit_user_path(user)
      user.reload
      user.password_reset_token.should be_nil
      user.password_reset_token_expires_at.should be_nil
      session[:user_id].should == user.id
    end
    it 'should not log in users with invalid reset password token' do
      user = User.gen(:password_reset_token => User.generate_key, :password_reset_token_expires_at => 24.hours.from_now)
      get :reset_password, :user_id => user.id, :password_reset_token => 'invalidtoken123'
      session[:user_id].should_not == user.id
      response.redirected_to.should == forgot_password_users_path
    end
    it 'should not log in users with expired reset password token' do
      user = User.gen(:password_reset_token => User.generate_key, :password_reset_token_expires_at => 24.hours.ago)
      get :reset_password, :user_id => user.id, :password_reset_token => 'invalidtoken123'
      session[:user_id].should_not == user.id
      response.redirected_to.should == forgot_password_users_path
    end
  end
end
