require File.dirname(__FILE__) + '/../spec_helper'

def create_user username, password
  user = User.gen :username => username, :password => password
  user.password = password
  user.save!
  user
end

describe 'User Profile' do

  before(:all) do
    truncate_all_tables
    load_foundation_cache
    Capybara.reset_sessions!
    @username = 'userprofilespec'
    @password = 'beforeall'
    @user     = create_user(@username, @password)
  end

  after(:each) do
    visit('/logout')
  end

  it 'should allow change of filter content hierarchy' do
    visit('/settings')
    body.should include('login')
    body.should include('Filter EOL')
    body.should have_tag('input#user_filter_content_by_hierarchy')
    login_as @user
    visit('/settings')
    body.should_not include('login')
    body.should include('Filter EOL')
    body.should have_tag('input#user_filter_content_by_hierarchy')
  end

  it 'should generate api key' do
    login_as @user
    visit('/settings')
    body.should include('Generate a key')
    click_button("Generate a key")
    body.should_not include("Generate a key")
    body.should include("Your key is")
  end

  it 'should show their "like" list'

  it 'should show their "task" list'

  it 'should show all of their specific lists'

  it 'should have a link to edit the name of specific lists'

  it 'should have a link to delete specific lists'

  it 'should NOT have a link to delete their task or like lists'

  it 'should have a link to create specific lists'

  it 'should have a link to convert specific lists to communities'

end
