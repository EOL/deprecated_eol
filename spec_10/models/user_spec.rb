require File.dirname(__FILE__) + '/../spec_helper'

describe User do

  fixtures :roles

  it '#create_valid should be valid' do
    User.create_valid!.should be_valid
  end

end

describe User, 'with fixtures' do

  fixtures :languages, :users, :agents, :roles

  before(:each) do
    @user = User.find(users(:jrice).id)
    @user_password = 'secret squirrel' # Don't change this password; it must match the YML fixture.
    @admin_password = 'admin' # Don't change this password; it must match the YML fixture.
    @user_params = {
      :id                     => Fixtures.identify(:jrice),
      :email                  => 'whatever@wherever.com',
      :username                   => 'stranger@knocking.com',
      :entered_password               => 'bestpasswordEVAR',
      :entered_password_confirmation  => 'bestpasswordEVAR',
      :given_name             => 'My Mommmy Gave me a Name',
      :family_name            => 'My Family Had a Name, Too',
      :expertise              => '',
      :language_abbr          => 'en',
      :mailing_list           => '',
      :content_level          => '',
      :active                 => true,
      :vetted                 => '',
      :credentials            => ''
    }
  end

  it 'should have the appropriate attributes' do
    @user.default_taxonomic_browser.should == users(:jrice).default_taxonomic_browser
    @user.expertise.should == users(:jrice).expertise
    @user.remote_ip.should == users(:jrice).remote_ip
    @user.content_level.should == users(:jrice).content_level
    @user.email.should == users(:jrice).email
    @user.given_name.should == users(:jrice).given_name
    @user.family_name.should == users(:jrice).family_name
    @user.flash_enabled.should == users(:jrice).flash_enabled
    @user.language_id.should == users(:jrice).language_id
    @user.vetted.should == users(:jrice).vetted
    @user.active.should == users(:jrice).active
    @user.mailing_list.should == users(:jrice).mailing_list
    @user.credentials.should == users(:jrice).credentials
  end

  it 'should authenticate existing user with correct password' do
    result = User.authenticate(users(:jrice).username, @user_password)
    result.should_not be_nil
    result.id.should == users(:jrice).id
  end

  it 'should return nil for non-existing user' do
    result = User.authenticate('idontexistATALL', @user_password) 
    result.should be_nil
  end

  it 'should return nil for user with incorrect password' do
    result = User.authenticate(users(:jrice).username, 'totally wrong password')
    result.should be_nil
  end

  it 'should fail to change password if the account is not found, either by not passing in a correct email or username or both' do
    results = User.reset_password('', 'junk')
    results.should_not be_nil
    results[0].should_not be_true
    results[1].should == 'Sorry, but we could not locate your account.'

    results = User.reset_password('junk@mail.com', '')
    results.should_not be_nil
    results[0].should_not be_true
    results[1].should == 'Sorry, but we could not locate your account.'

    results = User.reset_password('junk@email.com', 'more_junk')
    results.should_not be_nil
    results[0].should_not be_true
    results[1].should == 'Sorry, but we could not locate your account.'
  end

  it 'should fail to change password if only email addresses is entered and it is not unique' do
    results = User.reset_password(users(:jrice).email, '')
    results.should_not be_nil
    results[0].should_not be_true
    results[1].should == 'Sorry, but your email address is not unique - you must also specify a username.'
  end

  it 'should reset the password if only email address is entered and it is unique' do
    (results, password,email) = User.reset_password(users(:admin).email, '')
    results.should be_true
    password.should_not == @admin_user_password
    email.should == users(:admin).email
    # Check the DB, too:
    User.find(users(:admin).id).hashed_password.should == User.hash_password(password)
  end

  it 'should be able to reset the password on an account if both email address and username are entered' do
    (results, password, email) = User.reset_password(users(:jrice).email,users(:jrice).username)
    results.should be_true
    password.should_not == @user_password
    email.should == users(:jrice).email
    # Check the DB, too:
    User.find(users(:jrice).id).hashed_password.should == User.hash_password(password)
  end
  
  it 'should not create the same random password two times in a row...' do
    first_results  = User.reset_password(users(:jrice).email,users(:jrice).username)
    second_results = User.reset_password(users(:jrice).email,users(:jrice).username)
    first_results[1].should_not == second_results[1]
  end

  it 'should say a new username is unique' do
    User.unique_user?('this name does not exist').should be_true
  end

  it 'should say an existing username is not unique' do
    User.unique_user?(users(:jrice).username).should_not be_true
  end
  
  it 'should have defaults when creating a new user' do
    new_params={}
    user = User.create_new(new_params)
    user.expertise.should             == $DEFAULT_EXPERTISE.to_s
    user.language.id.should           == languages(:en).id
    user.mailing_list.should          == false
    user.content_level.should         == $DEFAULT_CONTENT_LEVEL.to_i
    user.vetted.should                == $DEFAULT_VETTED
    user.default_taxonomic_browser    == $DEFAULT_TAXONOMIC_BROWSER
    user.flash_enabled                == true
    user.active                       == true
  end

  it 'should not allow you to add a user that already exists' do
    @user_params[:username] = users(:jrice).username
    user=User.create_new(@user_params)
    result=user.save
    result.should_not be_true
  end

end
# == Schema Info
# Schema version: 20081020144900
#
# Table name: users
#
#  id                         :integer(4)      not null, primary key
#  curator_hierarchy_entry_id :integer(4)
#  curator_verdict_by_id      :integer(4)
#  language_id                :integer(4)
#  active                     :boolean(1)
#  content_level              :integer(4)
#  credentials                :text            not null
#  curator_approved           :boolean(1)      not null
#  default_taxonomic_browser  :string(24)
#  email                      :string(255)
#  expertise                  :string(24)
#  family_name                :string(255)
#  flash_enabled              :boolean(1)
#  given_name                 :string(255)
#  hashed_password            :string(32)
#  identity_url               :string(255)
#  mailing_list               :boolean(1)
#  notes                      :text
#  remote_ip                  :string(24)
#  username                   :string(32)
#  vetted                     :boolean(1)
#  created_at                 :datetime
#  curator_verdict_at         :datetime
#  updated_at                 :datetime

