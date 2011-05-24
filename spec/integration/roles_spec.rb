require File.dirname(__FILE__) + '/../spec_helper'

describe "Roles controller (within a community)" do

  before(:all) do
    truncate_all_tables
    load_foundation_cache
    Capybara.reset_sessions!
    @community = Community.gen
    @admin = User.gen
    @community.initialize_as_created_by(@admin)
    @role = Role.gen(:community => @community)
    @privilege1 = TranslatedPrivilege.gen.privilege
    @privilege2 = TranslatedPrivilege.gen.privilege
    @non_privilege = TranslatedPrivilege.gen.privilege
    @role.privileges = [@privilege1, @privilege2]
    @role.save!
    @has_role = User.gen.join_community(@community)
    @doesnt_have_role = User.gen.join_community(@community)
    @has_role.add_role(@role)
  end

  describe '#show (for non-admins)' do

    before(:all) do
      visit community_role_path(@community, @role)
    end

    it 'should show the name of the role' do
      page.should have_content(@role.title)
    end

    it 'should have a link to the community' do
      page.body.should have_tag("a[href=#{community_path(@community)}]", :text => @community.name)
    end

    it 'should list all of the role\'s privileges' do
      page.should have_content(@privilege1.name)
      page.should have_content(@privilege2.name)
    end

    it 'should NOT list any of the privilieges not included by the role' do
      page.should_not have_content(@non_privilege.name)
    end

    it 'should NOT have any remove links' do
      page.body.should_not
        have_tag("a[href=#{remove_privilege_from_role_path(:role_id => @role.id, :privilege_id => @privilege1.id)}]")
    end

  end

  it 'should not allow access to #new to those without... uhh... access' do
    visit logout_url
    get new_community_role_path(@community)
    response.should be_redirect
    response.body.should_not have_tag("input#role_title")
  end

  describe '#new' do

    before(:all) do
      login_as @admin
      visit new_community_role_path(@community)
    end

    it 'should ask for the title' do
      page.body.should have_tag("input#role_title")
    end

    it 'should have checkboxes for all of the Privileges' do
      Privilege.all_for_community(@community).each do |priv|
        page.body.should have_tag("input#privilege_#{priv.id}")
      end
    end

  end

  it 'should create new roles' do
    priv = Privilege.all_for_community(@community).last
    non_priv = Privilege.all_for_community(@community).first
    priv.should_not == non_priv
    title = 'Some New Title for a Role'
    login_as @admin
    visit new_community_role_path(@community)
    fill_in 'role_title', :with => title
    check "privilege_#{priv.id}"
    click 'Save'
    role = Role.last
    role.title.should == title
    role.community.should == @community
    page.should have_content('success')
    page.should have_content(title)
    # Checks that the priv we added can be removed (if it weren't added, it couldn't be):
    page.body.should have_tag("a[href=#{remove_privilege_from_role_path(:privilege_id => priv.id, :role_id => role.id)}]")
    page.body.should_not have_tag("a[href=#{remove_privilege_from_role_path(:privilege_id => non_priv.id, :role_id => role.id)}]")
  end

  describe '#show (for admins)' do

    before(:all) do
      login_as @admin
      visit community_role_path(@community, @role)
    end

    it 'should have a text field for editing the name of the role' do
      page.body.should have_tag("input#role_title[value=#{@role.title}]")
    end

    it 'should list ALL privileges availble to the community' do
      Privilege.all_for_community(@role.community).each do |priv|
        page.should have_content(priv.name)
      end
    end

    it 'should have remove links for privileges included in the role' do
      [@privilege1, @privilege2].each do |priv|
        page.body.should have_tag("a[href=#{remove_privilege_from_role_path(:privilege_id => priv.id, :role_id => @role.id)}]")
      end
    end

    it 'should have add links for privileges NOT included in the role' do
      page.body.should
        have_tag("a[href=#{add_privilege_to_role_path(:privilege_id => @non_privilege.id, :role_id => @role.id)}]")
    end

  end

end
