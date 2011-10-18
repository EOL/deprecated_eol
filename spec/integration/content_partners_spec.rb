require File.dirname(__FILE__) + '/../spec_helper'

def it_should_allow_access_to_partner_related_path(path, login_as_user = nil)
  unless login_as_user.nil?
    visit logout_path
    login_as login_as_user
  end
  visit path
  body.should have_tag('h1', @content_partner.full_name)
  current_path.should == path
end

def it_should_not_allow_access_to_partner_related_path(path, login_as_user = nil)
  unless login_as_user.nil?
    visit logout_path
    login_as login_as_user
  end
  visit path
  body.should_not have_tag('h1', @content_partner.full_name)
  current_path.should_not == path
end

describe 'Content Partners' do

# TODO: uncomment and fix - WIP
#  before :all do
#    unless @admin = User.find_by_username('content_partners_integration')
#      truncate_all_tables
#      load_foundation_cache
#      @admin = User.gen(:username => 'content_partners_integration', :admin => true)
#    end
#    @content_partner = ContentPartner.first
#    @owner = @content_partner.user
#    @non_owner = User.gen
#  end
#
#  shared_examples_for 'content_partners_all_users' do
#    it 'should be able to view public content partners and their statistics' do
#      visit content_partners_path
#      body.should have_tag('ul.object_list') do
#        with_tag('a', @content_partner.full_name)
#      end
#      visit user_content_partners_path(@owner)
#      body.should have_tag('ul') do
#        with_tag('a', @content_partner.full_name)
#      end
#      it_should_allow_access_to_partner_related_path(content_partner_path(@content_partner))
#      it_should_allow_access_to_partner_related_path(content_partner_statistics_path(@content_partner))
#    end
#    it 'should not be able to see private content partners in public listings' do
#      @content_partner.public = false
#      @content_partner.save(false)
#      visit content_partners_path
#      body.should have_tag('ul.object_list') do
#        without_tag('a', @content_partner.full_name)
#      end
#      visit user_content_partners_path(@owner)
#      body.should_not have_tag('ul') do
#        with_tag('a', @content_partner.full_name)
#      end
#      @content_partner.public == true
#      @content_partner.save(false)
#    end
#  end
#
#  shared_examples_for 'content_partners_not_owner_or_eol_administrator' do
#    it 'should not be able to access private content partners profiles or statistics' do
#      @content_partner.public = false
#      @content_partner.save(false)
#      visit content_partners_path
#      body.should have_tag('ul.object_list') do
#        without_tag('a', @content_partner.full_name)
#      end
#      it_should_not_allow_access_to_partner_related_path(content_partner_path(@content_partner))
#      it_should_not_allow_access_to_partner_related_path(content_partner_statistics_path(@content_partner))
#      @content_partner.public = true
#      @content_partner.save(false)
#    end
#    it 'should not be able to access or modify content partner contacts, resources, resource hierarchies and harvest events' do
#      it_should_not_allow_access_to_partner_related_path(edit_content_partner_path(@content_partner))
#      it_should_not_allow_access_to_partner_related_path(content_partner_resources_path(@content_partner))
#      it_should_not_allow_access_to_partner_related_path(content_partner_resource_path(@content_partner, @content_partner.resources.first))
#      it_should_not_allow_access_to_partner_related_path(new_content_partner_resource_path(@content_partner))
#      it_should_not_allow_access_to_partner_related_path(edit_content_partner_resource_path(@content_partner, @content_partner.resources.first))
#      # TODO: add more restricted paths
#    end
#  end
#
#  shared_examples_for 'content_partner_owner_or_eol_administrator' do
#    it 'should be able to access and modify partner information, statistics, contacts, resources, resource hierarchies and harvest events' do
#      it_should_allow_access_to_partner_related_path(content_partner_path(@content_partner))
#      it_should_allow_access_to_partner_related_path(content_partner_statistics_path(@content_partner))
#      it_should_allow_access_to_partner_related_path(content_partner_resources_path(@content_partner))
#      it_should_allow_access_to_partner_related_path(content_partner_resource_path(@content_partner, @content_partner.resources.first))
#      it_should_allow_access_to_partner_related_path(new_content_partner_resource_path(@content_partner))
#      it_should_allow_access_to_partner_related_path(edit_content_partner_resource_path(@content_partner, @content_partner.resources.first))
#      # TODO: add more paths
#    end
#  end
#
#  context 'anonymous users' do
#    before(:all) do
#      visit logout_url
#    end
#    it_should_behave_like 'content_partners_all_users'
#    it_should_behave_like 'content_partners_not_owner_or_eol_administrator'
#    it 'should not be able to create content partners' do
#      it_should_not_allow_access_to_partner_related_path(new_content_partner_path)
#    end
#  end
#
#  context 'logged in user not owner' do
#    before(:all) do
#      visit logout_url
#      login_as @non_owner
#    end
#    it_should_behave_like 'content_partners_all_users'
#    it_should_behave_like 'content_partners_not_owner_or_eol_administrator'
#    it 'should be able to create content partners' do
#      it_should_allow_access_to_partner_related_path(new_content_partner_path)
#    end
#  end
#
#  context 'owner' do
#    before(:all) do
#      visit logout_url
#      login_as @owner
#    end
#    it_should_behave_like 'content_partners_all_users'
#    it_should_behave_like 'content_partner_owner_or_eol_administrator'
#    it 'should not be able to see or edit public attribute on their partner profile'
#    it 'should not be able to see or edit vetted or auto_publish attributes on their resources'
#  end
#
#  context 'EOL administrators' do
#    before(:all) do
#      visit logout_url
#      login_as @admin
#    end
#    it_should_behave_like 'content_partners_all_users'
#    it_should_behave_like 'content_partner_owner_or_eol_administrator'
#    it 'should be able to create content partners for a user' do
#      user = User.gen
#      visit user_content_partners_path(user)
#      body.should have_tag('form#new_content_partner') do
#        with_tag('input[type=submit][value=?]', 'Add new content partner')
#        with_tag('input[type=hidden][name=?][value=?]', 'content_partner[user_id]', user.id)
#      end
#    end
#    it 'should be able to some attributes for a content partner'
#    it 'should be able to set vetted and auto_publish attributes for a content partner resource'
#    it 'should not be able to set a resource to unvetted once vetted is true' do
#      visit edit_content_partner_resource_path(@content_partner, @content_partner.resources.first)
#      body.should have_tag('input[name=?][checked=?][disabled=?]', 'resource[vetted]', 'checked', 'disabled')
#    end
#  end

end

