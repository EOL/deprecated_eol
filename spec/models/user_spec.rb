require File.dirname(__FILE__) + '/../spec_helper'

# I just want to avoid using #gen (which would require foundation scenario):
def bogus_hierarchy_entry
  HierarchyEntry.create(:guid => 'foo', :ancestry => '1', :depth => 1, :lft => 1, :rank_id => 1, :vetted_id => 1,
                        :parent_id => 1, :name_id => 1, :identifier => 'foo', :rgt => 2, :taxon_concept_id => 1,
                        :visibility_id => 1, :source_url => 'foo', :hierarchy_id => 1)
end

describe User do

  before(:all) do
    @password = 'dragonmaster'
    # We don't need foundation (which is expensive), but we do need curation permissions:
    KnownPrivileges.create_all
    Community.create_special
    User.delete_all
    @user = User.gen :username => 'KungFuPanda', :password => @password
    @user.should_not be_a_new_record
  end

  it "should generate a random hexadecimal key" do
    key = User.generate_key
    key.should match /[a-f0-9]{40}/
    User.generate_key.should_not == key
  end

  it 'should check master for accounts that cannot log in with email' do
    User.should_receive(:with_master).and_return(true)
    status, message = User.authenticate("invalid@some-place.org", @password)
    status.should_not be_true
    message.should =~ /please try again/i
  end

  it 'should hash passwords with MD5' do
    @pass = 'boogers'
    User.hash_password(@pass).should == Digest::MD5.hexdigest(@pass)
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

  it 'should provide a nice, empty version of a user with #create_new' do
    test_name = "Krampus"
    user = User.create_new(:username => test_name)
    user.username.should == test_name
    user.default_taxonomic_browser.should == $DEFAULT_TAXONOMIC_BROWSER
    user.expertise.should == $DEFAULT_EXPERTISE.to_s
    user.language.should == Language.english
    user.mailing_list.should == false
    user.content_level.should == $DEFAULT_CONTENT_LEVEL.to_i
    user.vetted.should == $DEFAULT_VETTED
    user.credentials.should == ''
    user.curator_scope.should == ''
    user.active.should == true
    user.flash_enabled.should == true
  end

  it 'should NOT log activity on a "fake" (unsaved, temporary, non-logged-in) user' do
    user = User.create_new
    count = ActivityLog.count
    user.log_activity(:clicked_link)
    ActivityLog.count.should == count
  end

  it 'should authenticate existing user with correct password, returning true and user back' do
    success, user=User.authenticate( @user.username, @password)
    success.should be_true
    user.id.should == @user.id
  end

  it 'should authenticate existing user with correct email address and password, returning true and user back' do
    success, user=User.authenticate( @user.email, @password )
    success.should be_true
    user.id.should == @user.id  
  end

  it 'should return false as first return value for non-existing user' do
    success, message=User.authenticate('idontexistATALL', @password)
    success.should be_false
    message.should == 'Invalid login or password'    
  end

  it 'should return false as first return value for user with incorrect password' do
    success, message=User.authenticate(@user.username, 'totally wrong password')
    success.should be_false
    message.should == 'Invalid login or password'
  end

  it 'should return url for the reset password email' do 
    user = User.gen(:username => 'johndoe', :email => 'johndoe@example.com') 
    user.password_reset_url(80).should match /http[s]?:\/\/.+\/account\/reset_password\//
    user.password_reset_url(3000).should match /http[s]?:\/\/.+:3000\/account\/reset_password\//
    user = User.find(user.id)
    user.password_reset_token.size.should == 40
    user.password_reset_token.should match /[\da-f]/
    user.password_reset_token_expires_at.should > 23.hours.from_now
    user.password_reset_token_expires_at.should < 24.hours.from_now
  end

  it 'should say a new username is unique' do
    User.unique_user?('this name does not exist').should be_true
  end

  it 'should say an existing username is not unique' do
    User.unique_user?(@user.username).should be_false
  end

  it 'should check for unique usernames on master' do
    User.should_receive(:with_master).and_return(true)
    User.unique_user?('whatever').should be_true
  end

  it 'should say a new email is unique' do
    User.unique_email?('this email does not exist').should be_true
  end

  it 'should say an existing email is not unique' do
    User.unique_email?(@user.email).should be_false
  end

  it 'should check for unique email on master' do
    User.should_receive(:with_master).and_return(true)
    User.unique_email?('whatever').should be_true
  end

  it 'should alias password to entered_password' do
    pass = 'something new'
    @user.entered_password = pass
    @user.password.should == pass
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

  it 'should fail validation if the email is in the wrong format' do
    user = User.create_new(:email => 'wrong(at)format(dot)com')
    user.valid?.should_not be_true
  end

  it 'should fail validation if the secondary hierarchy is the same as the first' do
    user = User.create_new(:default_hierarchy_id => 1, :secondary_hierarchy_id => 1)
    user.valid?.should_not be_true
  end

  it 'should fail validation if a curator requests a new account without credentials' do
    user = User.create_new(:curator_request => true, :credentials => '')
    user.valid?.should_not be_true
  end

  it 'should fail validation if a curator requests a new account without either a scope or a clade' do
    user = User.create_new(:curator_request => true, :curator_scope => nil, :curator_hierarchy_entry => nil)
    user.valid?.should_not be_true
  end

  it 'should build a full name out of a given name if that is all they provided' do
    given = 'bubba'
    user = User.create_new(:given_name => given, :family_name => '')
    user.full_name.should == given
  end

  it 'should build a full name out of a given and family names' do
    given = 'santa'
    family = 'klaws'
    user = User.create_new(:given_name => given, :family_name => family)
    user.full_name.should == "#{given} #{family}"
  end

  it 'should save some variables temporarily (by responding to some methods)' do
    @user.respond_to?(:entered_password).should be_true
    @user.respond_to?(:entered_password=).should be_true
    @user.respond_to?(:entered_password_confirmation).should be_true
    @user.respond_to?(:entered_password_confirmation=).should be_true
    @user.respond_to?(:curator_request).should be_true
    @user.respond_to?(:curator_request=).should be_true
  end

  it 'should not allow you to add a user that already exists' do
    User.create_new( :username => @user.username ).save.should be_false
  end

  describe('(curator user)') do

    before(:all) do
      @he = bogus_hierarchy_entry
      @curator = User.gen(:curator_hierarchy_entry => @he)
    end

    before(:each) do
      @curator.curator_hierarchy_entry = @he
      @curator.approve_to_curate
      @curator.save!
    end

    it 'should delegate can_curate? to the object passed in' do
      model = mock_model(DataObject)
      model.should_receive(:is_curatable_by?).with(@curator).and_return(true)
      @curator.can_curate? model
    end

    it 'should return false if asked to curate when curator not approved' do
      @curator.curator_approved = false
      @curator.can_curate?(@he).should be_false
    end

    it 'should return false if asked to curate when curator has no clade' do
      @curator.curator_hierarchy_entry = nil
      @curator.can_curate?(@he).should be_false
    end

    it 'should return false if asked to curate ... nothing' do
      @curator.can_curate?(nil).should be_false
    end

    it 'should raise an error if asked to curate something non-curatable' do
      lambda { @curator.can_curate?("a String").should be_false }.should raise_error
    end

    it 'should allow curator rights to be revoked' do
      Role.gen(:title => 'Curator') rescue nil
      @curator.is_curator?.should be_true
      @curator.clear_curatorship(User.gen, 'just because')
      @curator.reload
      @curator.is_curator?.should be_false
    end

  end

  describe("(in the special community)") do

    before(:all) do
      @special = Community.gen
      Community.stub!(:special).and_return(@special)
      @admin = User.gen(:username => 'MisterAdminToYouBuddy')
      @admin.join_community(@special)
    end

    it 'should be a member of the special community' do
      @admin.member_of?(@special).should be_true
    end

    it '#member_of should return a member of the special community' do
      @admin.member_of(@special).should be_a(Member)
    end

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
      @user.member_of?(community).should_not be_true
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
