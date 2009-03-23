require File.dirname(__FILE__) + '/../spec_helper'

describe User do

  before do
    @user = User.gen :username => 'KungFuPanda', :password => 'dragonwarrior'
    @user.should_not be_a_new_record
  end

  it 'should authenticate existing user with correct password' do
    User.authenticate( @user.username, @user.password ).id.should == @user.id
  end

  it 'should return nil for non-existing user' do
    User.authenticate('idontexistATALL', @user.password).should be_nil
  end

  it 'should return nil for user with incorrect password' do
    User.authenticate(@user.username, 'totally wrong password').should be_nil
  end

  it 'should fail to change password if the account is not found' do
    success, message = User.reset_password '', 'junk'
    success.should be_false
    message.should == 'Sorry, but we could not locate your account.'

    success, message = User.reset_password 'junk@mail.com', ''
    success.should be_false
    message.should == 'Sorry, but we could not locate your account.'

    success, message = User.reset_password 'junk@email.com', 'more_junk'
    success.should be_false
    message.should == 'Sorry, but we could not locate your account.'
  end

  it 'should fail to change password if only email addresses is entered and it is not unique' do
    User.gen :email => @user.email
    success, message = User.reset_password @user.email, ''
    success.should be_false
    message.should == 'Sorry, but your email address is not unique - you must also specify a username.'
  end

  it 'should reset the password if only email address is entered and it is unique' do
    # TODO this API is very smelly.  User#reset_password returns different kinds of
    #      results depending on whether the reset succeeded or failed.  very frustrating.
    #      this would be a good candicate for refactoring.
    success, password, email = User.reset_password @user.email, ''
    
    success.should be_true
    password.should_not == @user.password
    email.should == @user.email

    # confirm things really changed properly, in the database
    User.find(@user.id).hashed_password.should == User.hash_password(password)
    User.find(@user.id).hashed_password.should_not == @user.hashed_password
  end

  it 'should be able to reset the password on an account if both email address and username are entered' do
    success, password, email = User.reset_password @user.email, @user.username

    success.should be_true
    password.should_not == @user_password
    email.should == @user.email

    User.find(@user.id).hashed_password.should == User.hash_password(password)
    User.find(@user.id).hashed_password.should_not == @user.hashed_password
  end
  
  it 'should not create the same random password two times in a row...' do
    success1, password1, email1 = User.reset_password @user.email, @user.username
    success2, password2, email2 = User.reset_password @user.email, @user.username

    password1.should_not == password2
  end

  it 'should say a new username is unique' do
    User.unique_user?('this name does not exist').should be_true
  end

  it 'should say an existing username is not unique' do
    User.unique_user?(@user.username).should be_false
  end
  
  it 'should have defaults when creating a new user' do
    user = User.create_new
    user.expertise.should             == $DEFAULT_EXPERTISE.to_s
    user.mailing_list.should          == false
    user.content_level.should         == $DEFAULT_CONTENT_LEVEL.to_i
    user.vetted.should                == $DEFAULT_VETTED
    user.default_taxonomic_browser    == $DEFAULT_TAXONOMIC_BROWSER
    user.flash_enabled                == true
    user.active                       == true
  end

  it 'should not allow you to add a user that already exists' do
    User.create_new( :username => @user.username ).save.should be_false
  end

end
