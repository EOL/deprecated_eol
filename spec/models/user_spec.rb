require File.dirname(__FILE__) + '/../spec_helper'

describe User do

  before do
    @user = User.gen :username => 'KungFuPanda', :password => 'dragonwarrior'
    @user.should_not be_a_new_record
  end

  it 'should authenticate existing user with correct password, returning true and user back' do
    success,user=User.authenticate( @user.username, @user.password )
    success.should be_true
    user.id.should == @user.id
  end

  it 'should authenticate existing user with correct email address and password, returning true and user back' do
    success,user=User.authenticate( @user.email, @user.password )
    success.should be_true
    user.id.should == @user.id  
  end
      
  it 'should return false as first return value for non-existing user' do
    success,message=User.authenticate('idontexistATALL', @user.password)
    success.should be_false
    message.should == 'Invalid login or password'    
  end

  it 'should return false as first return value for user with incorrect password' do
    success,message=User.authenticate(@user.username, 'totally wrong password')
    success.should be_false
    message.should == 'Invalid login or password'
  end

  it 'should return url for the reset password email' do 
    url1 = /http[s]?:\/\/\/account\/reset_password\//
    url2 = /http[s]?:\/\/.*:3000\/account\/reset_password\//
    user = User.gen(:username => 'johndoe', :email => 'johndoe@example.com') 
    user.password_reset_url(80).should match url1
    user.password_reset_url(3000).should match url2
    user = User.find(user.id)
    user.password_reset_token.size.should == 40
    user.password_reset_token.should match /[\da-f]/
    user.password_reset_token_expires_at.should > 23.hours.from_now
    user.password_reset_token_expires_at.should < 24.hours.from_now
  end

# We should not need reset password anymore
#  it 'should fail to change password if the account is not found' do
#    success, message = User.reset_password '', 'junk'
#    success.should be_false
#    message.should == 'Sorry, but we could not locate your account.'
#
#    success, message = User.reset_password 'junk@mail.com', ''
#    success.should be_false
#    message.should == 'Sorry, but we could not locate your account.'
#
#    success, message = User.reset_password 'junk@email.com', 'more_junk'
#    success.should be_false
#    message.should == 'Sorry, but we could not locate your account.'
#  end
#
#  it 'should reset the password if only email address is entered and it is unique' do
#    # TODO this API is very smelly.  User#reset_password returns different kinds of
#    #      results depending on whether the reset succeeded or failed.  very frustrating.
#    #      this would be a good candicate for refactoring.
#    success, password, user = User.reset_password @user.email, ''
#    
#    success.should be_true
#    password.should_not == @user.password
#    user.email.should == @user.email
#
#    # confirm things really changed properly, in the database
#    User.find(@user.id).hashed_password.should == User.hash_password(password)
#    User.find(@user.id).hashed_password.should_not == @user.hashed_password
#  end

#  it 'should be able to reset the password on an account if both email address and username are entered' do
#    success, password, user = User.reset_password @user.email, @user.username
#
#    success.should be_true
#    password.should_not == @user_password
#    user.email.should == @user.email
#
#    User.find(@user.id).hashed_password.should == User.hash_password(password)
#    User.find(@user.id).hashed_password.should_not == @user.hashed_password
#  end
#  
#  it 'should not create the same random password two times in a row...' do
#    success1, password1, email1 = User.reset_password @user.email, @user.username
#    success2, password2, email2 = User.reset_password @user.email, @user.username
#
#    password1.should_not == password2
#  end
#
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

  describe 'convenience methods (NOT used in production code)' do

    # Okay, I could load foundation here and build a taxon concept... but that's heavy for what are really very
    # simple tests, so I'm doing a little more work here to save significant amounts of time running these tests:
    before(:each) do
      User.delete_all
      UsersDataObject.delete_all
      DataObject.delete_all
      @user = User.gen
      @descriptions = ['these', 'do not really', 'matter much'].sort
      @datos = @descriptions.map {|d| DataObject.gen(:description => d) }
      @dato_ids = @datos.map{|d| d.id}.sort
      @datos.each {|dato| UsersDataObject.create(:user_id => @user.id, :data_object_id => dato.id) }
    end

    it 'should return all of the data objects for the user' do
      @user.all_submitted_datos.map {|d| d.id }.should == @dato_ids
    end

    it 'should return all data objects descriptions' do
      @user.all_submitted_dato_descriptions.sort.should == @descriptions
    end

    it 'should be able to mark all data objects invisible and unvetted' do
      Vetted.gen(:label => 'Untrusted') unless Vetted.find_by_label('Untrusted')
      Visibility.gen(:label => 'Invisible') unless Visibility.find_by_label('Invisible')
      @user.hide_all_submitted_datos
      @datos.each do |stored_dato|
        new_dato = DataObject.find(stored_dato.id) # we changed the values, so must re-load them. 
        new_dato.vetted.should == Vetted.untrusted
        new_dato.visibility.should == Visibility.invisible
      end
    end

  end

end
