require File.dirname(__FILE__) + '/../spec_helper'

# I just want to avoid using #gen (which would require foundation scenario):
def bogus_hierarchy_entry
  HierarchyEntry.create(:guid => 'foo', :ancestry => '1', :depth => 1, :lft => 1, :rank_id => 1, :vetted_id => 1,
                        :parent_id => 1, :name_id => 1, :identifier => 'foo', :rgt => 2, :taxon_concept_id => 1,
                        :visibility_id => 1, :source_url => 'foo', :hierarchy_id => 1)
end

def rebuild_convenience_method_data
  @user = User.gen
  @descriptions = ['these', 'do not really', 'matter much'].sort
  @datos = @descriptions.map {|d| DataObject.gen(:description => d) }
  @dato_ids = @datos.map{|d| d.id}.sort
  @datos.each {|dato| UsersDataObject.create(:user_id => @user.id, :data_object_id => dato.id, :vetted => Vetted.trusted) }
end

describe User do

  before(:all) do
    @password = 'dragonmaster'
    load_foundation_cache
    @user = User.gen :username => 'KungFuPanda', :password => @password
    @user.should_not be_a_new_record
    @admin = User.gen(:username => 'MisterAdminToYouBuddy')
    @admin.grant_admin
    @he = bogus_hierarchy_entry
    @curator = User.gen(:credentials => 'whatever', :curator_scope => 'whatever')
  end

  it "should generate a random hexadecimal key" do
    key = User.generate_key
    key.should match /[a-f0-9]{40}/
    User.generate_key.should_not == key
  end

  it 'should tell us if an account is active on master' do
    User.should_receive(:with_master).and_return(true)
    status = User.active_on_master?("invalid@some-place.org")
    status.should be_true
  end

  it 'should hash passwords with MD5' do
    @pass = 'boogers'
    User.hash_password(@pass).should == Digest::MD5.hexdigest(@pass)
  end

  it 'should have a log method that creates a UserActivityLog entry (when enabled)' do
    old_log_val = $LOG_USER_ACTIVITY
    begin
      $LOG_USER_ACTIVITY = true
      count = UserActivityLog.count
      @user.log_activity(:clicked_link)
      wait_for_insert_delayed do
        UserActivityLog.count.should == count + 1
      end
      UserActivityLog.last.user_id.should == @user.id
    ensure
      $LOG_USER_ACTIVITY = old_log_val
    end
  end

  it 'should NOT log activity on a "fake" (unsaved, temporary, non-logged-in) user' do
    user = User.new
    count = UserActivityLog.count
    user.log_activity(:clicked_link)
    UserActivityLog.count.should == count
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
    success, user = User.authenticate('idontexistATALL', @password)
    success.should be_false
    user.should be_blank
  end

  it 'should return false as first return value for user with incorrect password' do
    success, user = User.authenticate(@user.username, 'totally wrong password')
    success.should be_false
    user.first.id.should == @user.id
  end

  it 'should generate reset password token' do
    token = User.generate_key
    token.size.should == 40
    token.should match /[\da-f]/
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

  it 'should require password for a user with eol authentication'
  it 'should require username for a user with eol authentication'
  it 'should require email for a user with eol authentication'

  it 'should not require username or password for open authenticated user' do
    user = User.new(:given_name => "Oauth", :email => 'email@example.com',
                    :open_authentications_attributes => [ { :guid => 1234, :provider => 'facebook' }])
    user.valid?.should be_true
  end

  it 'should require given name for open authenticated user' do
    user = User.new(:open_authentications_attributes => [ { :guid => 1234, :provider => 'facebook' }])
    user.valid?.should be_false
    user.errors.on(:given_name).should =~ /can't be blank/
    user.given_name = "Oauth"
    user.valid? # run validations again - will still fail due to other errors but we're just checking given name
    user.errors.on(:given_name).should be_nil
  end

  it 'should fail validation if the email is in the wrong format' do
    user = User.new(:email => 'wrong(at)format(dot)com')
    user.valid?.should be_false
    user.errors.on(:email).should =~ /is invalid/
  end

  it 'should fail validation if master or full curator does not provide credentials or scope' do
    [CuratorLevel.master.id, CuratorLevel.full.id].each do |curator_level_id|
      user1 = User.new(:requested_curator_level_id => curator_level_id)
      user2 = User.new(:curator_level_id => curator_level_id)
      [user1, user2].each do |user|
        user.valid?.should be_false
        user.errors.on(:credentials).should =~ /can't be blank/
        user.errors.on(:curator_scope).should =~ /can't be blank/
      end
    end
    user = User.new(:curator_level_id => CuratorLevel.assistant.id)
    user.valid?
    user.errors.on(:credentials).should be_nil
    user.errors.on(:curator_scope).should be_nil
  end

  it '#full_name should resort to username if a given name is all they provided' do
    given = 'bubba'
    username = 'carryoncarryon'
    user = User.new(:username => username, :given_name => given, :family_name => '')
    user.full_name.should == username
  end

  it '#full_name should build a full name out of a given and family names' do
    given = 'santa'
    family = 'klaws'
    user = User.new(:given_name => given, :family_name => family)
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
    user = User.new(:username => @user.username)
    user.save.should be_false
    user.errors.on(:username).should =~ /taken/
  end

  it '(curator user) should allow curator rights to be revoked' do
    Role.gen(:title => 'Curator') rescue nil
    @curator.approve_to_curate
    @curator.save!
    @curator.curator_level_id.nil?.should_not be_true
    @curator.revoke_curator
    @curator.reload
    @curator.curator_level_id.nil?.should be_true
  end

  it 'convenience methods should return all of the data objects for the user' do
    rebuild_convenience_method_data
    @user.all_submitted_datos.map {|d| d.id }.should == @dato_ids
  end

  it 'convenience methods should return all data objects descriptions' do
    rebuild_convenience_method_data
    @user.all_submitted_dato_descriptions.sort.should == @descriptions
  end

  # TODO - This test should be modified/rewritten while working on WEB-2542
  it 'convenience methods should be able to mark all data objects invisible and unvetted' # do
   #    rebuild_convenience_method_data
   #    Vetted.gen_if_not_exists(:label => 'Untrusted') unless Vetted.find_by_translated(:label, 'Untrusted')
   #    Visibility.gen_if_not_exists(:label => 'Invisible') unless Visibility.find_by_translated(:label, 'Invisible')
   #    @user.hide_all_submitted_datos
   #    @datos.each do |stored_dato|
   #
   #      new_dato = DataObject.find(stored_dato.id) # we changed the values, so must re-load them.
   #      new_dato.vetted.should == Vetted.untrusted
   #      new_dato.visibility.should == Visibility.invisible
   #    end
   #  end

  it 'should set the active boolean' do
    inactive_user = User.gen(:active => false)
    inactive_user.active?.should_not be_true
    inactive_user.activate
    inactive_user.active?.should be_true
  end

  it 'should create a "watch" collection' do
    inactive_user = User.gen(:active => false)
    inactive_user.activate
    inactive_user.watch_collection.should_not be_nil
    inactive_user.watch_collection.name.should == "#{inactive_user.full_name.titleize}'s Watch List"
  end

  it 'should update the "watch" collection if member updates the full name' do
    full_name = @user.full_name
    @user.watch_collection.name.should == "#{@user.full_name.titleize}'s Watch List"
    @user.given_name = 'lazy'
    @user.family_name = 'smurf'
    @user.save
    @user.reload
    @user.run_callbacks(:after_save)
    @user.full_name.should_not == full_name
    @user.watch_collection.name.should == "#{@user.full_name.titleize}'s Watch List"
  end

  it 'community membership should be able to join a community' do
    community = Community.gen
    community.members.should be_blank
    @user.join_community(community)
    @user.members.map {|m| m.community_id}.should include(community.id)
  end

  it 'community membership should be able to answer member_of?' do
    community = Community.gen
    @user.member_of?(community).should_not be_true
    another_user = User.gen
    community.add_member(@user)
    @user.member_of?(community).should be_true
    another_user.member_of?(community).should_not be_true
  end

  it 'community membership should be able to leave a community' do
    community = Community.gen
    community.add_member(@user)
    @user.member_of?(community).should be_true
    @user.leave_community(community)
    @user.member_of?(community).should_not be_true
  end

  it 'should have an activity log' do
    user = User.gen
    user.respond_to?(:activity_log).should be_true
    user.activity_log.should be_a WillPaginate::Collection
  end

  it '#is_admin? should return true if current user is admin, otherwise false' do
    user = User.gen
    user.admin = 0                  # non-admin user
    user.is_admin?.should == false
    user.grant_admin                # admin user
    user.is_admin?.should == true
    user.admin = nil                # anonymous user
    user.is_admin?.should == false
  end

  it 'should increase no. of curated data objects for a curator' do
      temp_count = User.total_objects_curated_by_action_and_user(nil, @curator.id)

      data_object = DataObject.gen()
      activity = CuratorActivityLog.gen(:user => @curator, :object_id => data_object.id, :changeable_object_type_id => ChangeableObjectType.data_objects_hierarchy_entry.id, :activity_id => TranslatedActivity.find_by_name("trusted").id )
      temp_count2 = User.total_objects_curated_by_action_and_user(nil, @curator.id)
      temp_count2.should > temp_count

      data_object = DataObject.gen()
      activity = CuratorActivityLog.gen(:user => @curator, :object_id => data_object.id, :changeable_object_type_id => ChangeableObjectType.curated_data_objects_hierarchy_entry.id, :activity_id => TranslatedActivity.find_by_name("trusted").id )
      temp_count = User.total_objects_curated_by_action_and_user(nil, @curator.id)
      temp_count.should > temp_count2

      data_object = DataObject.gen()
      activity = CuratorActivityLog.gen(:user => @curator, :object_id => data_object.id, :changeable_object_type_id => ChangeableObjectType.users_data_object.id, :activity_id => TranslatedActivity.find_by_name("trusted").id )
      temp_count2 = User.total_objects_curated_by_action_and_user(nil, @curator.id)
      temp_count2.should > temp_count

      data_object = DataObject.gen()
      activity = CuratorActivityLog.gen(:user => @curator, :object_id => data_object.id, :changeable_object_type_id => ChangeableObjectType.data_object.id, :activity_id => TranslatedActivity.find_by_name("trusted").id )
      temp_count = User.total_objects_curated_by_action_and_user(nil, @curator.id)
      temp_count.should > temp_count2
  end

  it 'should increase no. of curated taxa for a curator' do
      temp_count = @curator.total_species_curated

      taxon_concept = TaxonConcept.gen()
      data_object = DataObject.gen()
      dotc = DataObjectsTaxonConcept.gen(:taxon_concept => taxon_concept, :data_object => data_object)
      activity = CuratorActivityLog.gen(:user => @curator, :object_id => data_object.id, :changeable_object_type_id => ChangeableObjectType.data_objects_hierarchy_entry.id, :activity_id => TranslatedActivity.find_by_name("trusted").id )
      temp_count2 = @curator.total_species_curated
      temp_count2.should > temp_count

      taxon_concept = TaxonConcept.gen()
      data_object = DataObject.gen()
      dotc = DataObjectsTaxonConcept.gen(:taxon_concept => taxon_concept, :data_object => data_object)
      activity = CuratorActivityLog.gen(:user => @curator, :object_id => data_object.id, :changeable_object_type_id => ChangeableObjectType.data_objects_hierarchy_entry.id, :activity_id => TranslatedActivity.find_by_name("trusted").id )
      temp_count = @curator.total_species_curated
      temp_count.should > temp_count2
  end

  it 'should increase no. of articles added for a curator' do
    temp_count = UsersDataObject.count(:conditions => ['user_id = ?',@curator.id])

    taxon_concept = TaxonConcept.gen()
    data_object = DataObject.gen()
    udo = UsersDataObject.gen(:user => @curator, :taxon_concept => taxon_concept, :data_object => data_object, :vetted_id => Vetted.trusted)
    temp_count2 = UsersDataObject.count(:conditions => ['user_id = ?',@curator.id])
    temp_count2.should > temp_count

    taxon_concept = TaxonConcept.gen()
    data_object = DataObject.gen()
    udo = UsersDataObject.gen(:user => @curator, :taxon_concept => taxon_concept, :data_object => data_object, :vetted_id => Vetted.trusted)
    temp_count = UsersDataObject.count(:conditions => ['user_id = ?',@curator.id])
    temp_count.should > temp_count2
  end

end
