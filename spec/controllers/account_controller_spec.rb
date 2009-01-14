require File.dirname(__FILE__) + '/../spec_helper'

describe AccountController do
  
  fixtures :users, :hierarchy_entries, :roles
  
  before(:each) do
   (@fake_username, @fake_password,@fake_incorrect_password,@fake_email) = ['stranger', 'badpassword', 'incorrect_password','whatever@wherever.com']
    @fake_user = mock_model(User)
    @user_params = { :user => {
        :id                     => Fixtures.identify(:jrice),
        :email                  => 'whatever@wherever.com',
        :username               => 'stranger',
        :password               => 'badpassword',           
        :given_name             => 'My Mommmy Gave me a Name',
        :family_name            => 'My Family Had a Name, Too',
        :expertise              => 'middle',
        :language_abbr          => 'en',
        :mailing_list           => false,
        :content_level          => '',
        :active                 => true,
        :vetted                 => false
      } }
    @new_user_params = { :user => {
        :email                  => 'a_new_user@wherever.com',
        :username               => 'newuser',     
        :entered_password       => 'badpassword2',
        :entered_password_confirmation => 'badpassword2',      
        :given_name             => 'Given Name',
        :family_name            => 'Family Name',
        :expertise              => 'middle',
        :language_abbr          => 'en',
        :mailing_list           => false,
        :content_level          => '',   
        :vetted                 => false,
        :credentials            => 'President of the United States: 2005-2008'
      } } 
    #    @new_user_params_with_curator = @new_user_params.clone.merge({:user => {:curator => 1, :curator_hierarchy_entry_id => hierarchy_entries(:h2_cafeteria).id}})    
    @openid_params = { :openid_url => 'bogus@bogus.com' }
  end
  
  it 'should fail to authenticate a user on post to login with wrong password' do
    User.should_receive(:authenticate).with(@fake_username, @fake_incorrect_password).and_return(nil)
    @user_params[:user][:password]=@fake_incorrect_password
    post 'authenticate', @user_params
    response.should redirect_to(login_url)
    flash[:warning].should == 'Invalid login or password'
  end
  
  it 'should authenticate a user on post to login with username and password' do
    User.should_receive(:authenticate).with(@fake_username, @fake_password).and_return(@fake_user)
    post 'authenticate', @user_params
    response.should redirect_to(home_page_url)
    flash[:notice].should == 'Logged in successfully'
  end
  
  it 'should fail to login a bogus openid request' do
    post 'authenticate', @openid_params
    response.should redirect_to(login_url)
    flash[:warning].should == 'Sorry, the OpenID server couldn\'t be found'
  end
  
  it 'should create a user in the database and add user to session on post to signup' do
    
    session[:user].should be_nil
    
    post 'signup', @new_user_params 
    flash[:notice].should == 'Logged in successfully'
    
    # check database to be sure the new user is there
    new_user=User.find_by_username(@new_user_params[:user][:username])
    new_user.email.should == @new_user_params[:user][:email]
    new_user.roles.should == []
    
    # check session to be user it was set
    session[:user].should_not be_nil
    session[:user].id.should_not be_nil
    session[:user].should == new_user
    
    ## TO DO: This should work, but for some reason it throws a failure
    #  Notifier.should_receive(:deliver_welcome_registration).with(new_user).and_return(nil)
    
  end
  
  it 'should NOT create a user in the database if the passwords do not match' do
    
    session[:user].should be_nil
    
    wrong_user_params=@new_user_params.dup
    wrong_user_params[:user][:entered_password]='junk1'
    wrong_user_params[:user][:entered_password_confirmation]='junk2'
    
    post 'signup', wrong_user_params 
    
    # check database to be sure the new user is NOT there
    User.find_by_username(wrong_user_params[:user][:name]).should be_nil
    
    session[:user].should_not be_nil
    session[:user].id.should be_nil
    
  end
  
  it 'should call reset password on post to forgot_password' do
    User.should_receive(:reset_password).with(@fake_email,@fake_username).and_return([true, 'whatever',@fake_email])
    Notifier.should_receive(:deliver_forgot_password_email).with(@fake_username, 'whatever', @fake_email).and_return(nil)
    post 'forgot_password', @user_params
    response.should be_success
    flash[:notice].should == "A new password has been emailed to you."
  end
  
  
  it 'should allow a user to skip curation privilege request on initial signup' do
    session[:user].should be_nil
    
    post 'signup', @new_user_params 
    flash[:notice].should == 'Logged in successfully'
    
    new_user = User.find_by_username(@new_user_params[:user][:username])
    
    session[:user].should_not be_nil
    session[:user].id.should_not be_nil
    session[:user].should == new_user
    session[:user].curator_hierarchy_entry.should be_nil
  end
  
  it 'should allow a user to request curation privileges on initial signup' do
    session[:user].should be_nil
    
    cafe = hierarchy_entries(:h2_cafeteria)
    params = @new_user_params.clone.merge({'selected-clade-id'.to_sym => cafe.id})
    post 'signup', params 
    flash[:notice].should == 'Logged in successfully'
    
    new_user = User.find_by_username(@new_user_params[:user][:username])
    
    session[:user].should_not be_nil
    session[:user].id.should_not be_nil
    session[:user].should == new_user
    
    session[:user].curator_hierarchy_entry_id.should == cafe.id
  end
  
  it 'should allow a user to update their credentials' do
    creds = 'awwwwwww yeeeaaaaah!'
    update_params = {:user =>{:credentials => creds}}
    login_as(:jrice)
    session[:user].should_not be_nil
    post :profile, update_params
    response.should be_redirect    
    User.find_by_username('jrice').credentials.should == creds
  end
  
  it 'should not allow a non-admin user to change their approved curation clade' do
    update_params = {:user => {:curator_hierarchy_entry_id => hierarchy_entries(:h2_chromista).id}}
    
    session[:user].should be_nil
    
    users(:jrice).curator_hierarchy_entry.should == hierarchy_entries(:h2_cafeteria)
    post :profile, update_params
    response.should_not be_success
    
    # Now try again while logged in legitimately.
    login_as(:jrice)
    session[:user].should_not be_nil
    post :profile, update_params
    response.should be_redirect
    
    # But the HE should not have changed!
    User.find_by_username('jrice').curator_hierarchy_entry.should == hierarchy_entries(:h2_cafeteria)
  end
  
  it 'should allow an admin user to change the approved clade of themselves'
  it 'should allow an admin user to change the approved clade of a different user'
  
  def login_as(user)
    @request.session[:user] = users(user)
  end
  
  it 'should not show a profile page for a user without approved curation privileges' do
    get :show, :id => users(:jrice2).id
    response.should be_redirect
  end

  it 'should show a profile page for a user with approved curation privileges' do    
    get :show, :id => users(:admin).id
    response.should be_success
  end
  
end
