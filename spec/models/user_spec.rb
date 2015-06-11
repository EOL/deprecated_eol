require "spec_helper"

describe User do

  def rebuild_convenience_method_data
    @user = User.gen
    @descriptions = ['these', 'do not really', 'matter much'].sort
    @datos = @descriptions.map {|d| DataObject.gen(description: d) }
    @dato_ids = @datos.map{|d| d.id}.sort
    @datos.each {|dato| UsersDataObject.create(user_id: @user.id, data_object_id: dato.id, vetted: Vetted.trusted) }
  end

  def expect_permission_count_to_be(perm, count)
    Permission.send(perm).reload.users_count.should == count
  end

  before(:all) do
    I18n.locale = 'en'
    @password = 'dragonmaster'
    load_foundation_cache
    @user = User.gen username: 'KungFuPanda', password: @password
    @user.should_not be_a_new_record
    @admin = User.gen(username: 'MisterAdminToYouBuddy')
    @admin.grant_admin
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

  it 'should hash unsubscribe_keys with MD5' do
    @user.unsubscribe_key.should == Digest::MD5.hexdigest(@user.email + @user.created_at.to_s + $UNSUBSCRIBE_NOTIFICATIONS_KEY)
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

  it 'should alias password to entered_password' do
    user = User.new
    pass = 'something new'
    user.entered_password = pass
    user.password.should == pass
  end

  it 'should require password for a user with eol authentication'
  it 'should require username for a user with eol authentication'
  it 'should require email for a user with eol authentication'

  it 'should not require username or password for open authenticated user' do
    user = User.new(given_name: "Oauth", email: 'email@example.com',
                    open_authentications_attributes: [ { guid: 1234, provider: 'facebook' }])
    user.valid?.should be_true
  end

  it 'should require given name for open authenticated user' do
    user = User.new(open_authentications_attributes: [ { guid: 1234, provider: 'facebook' }])
    user.valid?.should be_false
    user.errors[:given_name].to_s.should =~ /can't be blank/
    user.given_name = "Oauth"
    user.valid? # run validations again - will still fail due to other errors but we're just checking given name
    user.errors.include?(:given_name).should_not be_true
  end

  it 'should fail validation if the email is in the wrong format' do
    user = User.new(email: 'wrong(at)format(dot)com')
    user.valid?.should be_false
    user.errors[:email].to_s.should =~ /is invalid/
  end

  it '#full_name should resort to username if a given name is all they provided' do
    given = 'bubba'
    username = 'carryoncarryon'
    user = User.new(username: username, given_name: given, family_name: '')
    user.full_name.should == username
  end

  it '#full_name should build a full name out of a given and family names' do
    given = 'santa'
    family = 'klaws'
    user = User.new(given_name: given, family_name: family)
    user.full_name.should == "#{given} #{family}"
  end

  it 'should save some variables temporarily (by responding to some methods)' do
    @user.respond_to?(:entered_password).should be_true
    @user.respond_to?(:entered_password=).should be_true
    @user.respond_to?(:entered_password_confirmation).should be_true
    @user.respond_to?(:entered_password_confirmation=).should be_true
  end

  it 'should not allow you to add a user that already exists' do
    user = User.new(username: @user.username)
    user.save.should be_false
    user.errors[:username].to_s.should =~ /taken/
  end

  it 'convenience methods should return all of the data objects for the user' do
    rebuild_convenience_method_data
    @user.all_submitted_datos.map {|d| d.id }.should == @dato_ids
  end

  it 'convenience methods should return all data objects descriptions' do
    rebuild_convenience_method_data
    @user.all_submitted_dato_descriptions.sort.should == @descriptions
  end

  it 'convenience methods should be able to mark all data objects invisible and unvetted' do
    rebuild_convenience_method_data
    Vetted.gen_if_not_exists(label: 'Untrusted') unless Vetted.find_by_translated(:label, 'Untrusted')
    Visibility.gen_if_not_exists(label: 'Invisible') unless Visibility.find_by_translated(:label, 'Invisible')
    @user.hide_all_submitted_datos
    @datos.each do |stored_dato|
      new_dato = DataObject.find(stored_dato.id) # we changed the values, so must re-load them.
      new_dato.users_data_object.vetted.should == Vetted.untrusted
      new_dato.users_data_object.visibility.should == Visibility.invisible
    end
  end

  it 'should set the active boolean' do
    inactive_user = User.gen(active: false)
    inactive_user.active?.should_not be_true
    inactive_user.activate
    inactive_user.active?.should be_true
  end

  it 'should create a "watch" collection' do
    inactive_user = User.gen(active: false)
    inactive_user.activate
    inactive_user.watch_collection.should_not be_nil
    inactive_user.watch_collection.name.should == "#{inactive_user.full_name.titleize}'s Watch List"
  end

  it 'should update the "watch" collection if member updates the full name' do
    full_name = @user.full_name
    @user.watch_collection.name.should == "#{@user.full_name.titleize}'s Watch List"
    @user.given_name += 'lazy'
    @user.family_name += 'smurf'
    @user.save
    @user.reload
    @user.full_name.should_not == full_name
    @user.watch_collection.name.should == "#{@user.full_name.titleize}'s Watch List"
  end

  it 'community membership should be able to join a community' do
    community = Community.gen
    community.members.should be_blank
    @user.join_community(community)
    @user.members.map {|m| m.community_id}.should include(community.id)
  end

  it 'community membership should be able to answer is_member_of?' do
    community = Community.gen
    @user.is_member_of?(community).should_not be_true
    another_user = User.gen
    community.add_member(@user)
    @user.is_member_of?(community).should be_true
    another_user.is_member_of?(community).should_not be_true
  end

  it 'community membership should be able to leave a community' do
    community = Community.gen
    community.add_member(@user)
    @user.is_member_of?(community).should be_true
    @user.leave_community(community)
    @user.is_member_of?(community).should_not be_true
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

  it 'should know when a user has a permission' do
    # Silly but required because of uses_translations:
    user = User.gen
    user.permissions << Permission.edit_permissions
    user.can?(:edit_permissions).should be_true
    user.can?(:beta_test).should_not be_true
  end

  it 'should grant permissions' do
    count = Permission.edit_permissions.reload.users_count
    user = User.gen
    user.permissions.length.should == 0
    user.can?(:edit_permissions).should_not be_true
    user.grant_permission(:edit_permissions)
    user.permissions.length.should == 1
    user.can?(:edit_permissions).should be_true
    expect_permission_count_to_be(:edit_permissions, count + 1)
    # Make sure doing it twice doesn't hurt:
    user.grant_permission(:edit_permissions)
    user.can?(:edit_permissions).should be_true
    user.permissions.length.should == 1
    expect_permission_count_to_be(:edit_permissions, count + 1)
  end

  it 'should revoke permissions' do
    user = User.gen
    user.grant_permission(:edit_permissions)
    user.permissions.length.should == 1
    user.can?(:edit_permissions).should be_true
    count = Permission.edit_permissions.reload.users_count
    user.revoke_permission(:edit_permissions)
    expect_permission_count_to_be(:edit_permissions, count - 1)
    user.permissions.length.should == 0
    # Make sure doing it twice doesn't hurt:
    user.revoke_permission(:edit_permissions)
    expect_permission_count_to_be(:edit_permissions, count - 1)
    user.permissions.length.should == 0
  end

  it 'should can_see_data? when they have permission' do
    EolConfig.destroy_all
    u = User.gen
    u.can_see_data?.should == false
    u.grant_permission(:see_data)
    u.can_see_data?.should == true
  end

  it 'should can_see_data? when the site configuration option is set' do
    EolConfig.destroy_all
    u = User.gen
    u.can_see_data?.should == false
    EolConfig.gen(parameter: 'all_users_can_see_data', value: true)
    u.can_see_data?.should == true
    u = User.gen
  end

end
