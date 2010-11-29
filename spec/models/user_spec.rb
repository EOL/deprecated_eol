require File.dirname(__FILE__) + '/../spec_helper'

# I just want to avoid using #gen (which would require foundation scenario):
def bogus_hierarchy_entry
  HierarchyEntry.create(:guid => 'foo', :ancestry => '1', :depth => 1, :lft => 1, :rank_id => 1, :vetted_id => 1,
                        :parent_id => 1, :name_id => 1, :identifier => 'foo', :rgt => 2, :taxon_concept_id => 1,
                        :visibility_id => 1, :source_url => 'foo', :hierarchy_id => 1)
end

describe User do

  before do
    @password = 'dragonmaster'
    @user = User.gen :username => 'KungFuPanda', :password => @password
    @user.should_not be_a_new_record
  end

  describe "::generate_key" do

    it "should generate a random hexadecimal key" do
      key = User.generate_key
      key.should match /[a-f0-9]{40}/
      User.generate_key.should_not == key
    end

  end

  it 'should have a log method that creates an ActivityLog entry (when enabled)' do
    old_log_val = $LOG_USER_ACTIVITY
    begin
      $LOG_USER_ACTIVITY = true
      count = ActivityLog.count
      @user.log_activity(:clicked_link)
      wait_for_insert_delayed do
        ActivityLog.count.should == count + 1
      end
      ActivityLog.last.user_id.should == @user.id
    ensure
      $LOG_USER_ACTIVITY = old_log_val
    end
  end

  it 'should NOT log activity on a "fake" (unsaved, temporary, non-logged-in) user' do
    user = User.create_new
    count = ActivityLog.count
    user.log_activity(:clicked_link)
    ActivityLog.count.should == count
  end

  it 'should authenticate existing user with correct password, returning true and user back' do
    success,user=User.authenticate( @user.username, @password)
    success.should be_true
    user.id.should == @user.id
  end

  it 'should authenticate existing user with correct email address and password, returning true and user back' do
    success,user=User.authenticate( @user.email, @password )
    success.should be_true
    user.id.should == @user.id  
  end
      
  it 'should return false as first return value for non-existing user' do
    success,message=User.authenticate('idontexistATALL', @password)
    success.should be_false
    message.should == 'Invalid login or password'    
  end

  it 'should return false as first return value for user with incorrect password' do
    success,message=User.authenticate(@user.username, 'totally wrong password')
    success.should be_false
    message.should == 'Invalid login or password'
  end

  it 'should return url for the reset password email' do 
    #url1 = /http[s]?:\/\/.+\/account\/reset_password\//
    #url2 = /http[s]?:\/\/.+:3000\/account\/reset_password\//

    url1 = /http[s]?:\/\/.+\/account\/reset_password\//
    url2 = /http[s]?:\/\/.+:3000\/account\/reset_password\//
    
    
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

  it 'should allow curator rights to be revoked' do
    Role.gen(:title => 'Curator') rescue nil
    he = bogus_hierarchy_entry
    curator_user = User.gen(:curator_hierarchy_entry => he)
    curator_user.roles << Role.curator
    curator_user.save!
    curator_user.is_curator?.should be_true
    curator_user.clear_curatorship(User.gen, 'just because')
    curator_user.reload
    curator_user.is_curator?.should be_false
  end

  it 'should create a new ActionsHistory pointing to the right object, user, type and action' do      
    action = ActionWithObject.create(:action_code => 'hi')
    obj    = ChangeableObjectType.create(:ch_object_type => 'name')
    name   = Name.gen
    @user.track_curator_activity(name, obj.ch_object_type, action.action_code)
    ActionsHistory.last.user_id.should                   == @user.id
    ActionsHistory.last.object_id.should                 == name.id
    ActionsHistory.last.changeable_object_type_id.should == obj.id
    ActionsHistory.last.action_with_object_id.should     == action.id
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

  describe 'community membership' do

    it 'should be able to join a community' do
      community = Community.gen
      community.members.should be_blank
      @user.join_community(community)
      @user.members.map {|m| m.community_id}.should include(community.id)
    end

    it 'should be able to answer member_of?' do
      community = Community.gen
      community.members.should be_blank
      another_user = User.gen
      community.add_member(@user)
      @user.member_of?(community).should be_true
      another_user.member_of?(community).should_not be_true
    end

    it 'should be able to leave a community' do
      community = Community.gen
      community.add_member(@user)
      @user.member_of?(community).should be_true
      @user.leave_community(community)
      @user.member_of?(community).should_not be_true
    end

  end

end
