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
    @user.feed.post @feed_body_1 = "Something"
    @user.feed.post @feed_body_2 = "Something Else"
    @user.feed.post @feed_body_3 = "Something More"
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

  describe '#show' do

    before(:each) do
      visit(user_path(@user))
    end

    it 'should show their "like" list'

    it 'should show their "task" list'

    it 'should show all of their specific lists'

    it 'should show their feed' do
      page.body.should have_tag('ul.feed') do
        with_tag('.feed_item .body', :text => @feed_body_1)
        with_tag('.feed_item .body', :text => @feed_body_2)
        with_tag('.feed_item .body', :text => @feed_body_3)
      end
    end

    it 'should show an empty feed' do
      @lonely_user = User.gen
      visit(user_path(@lonely_user))
      page.body.should have_tag('#activity', :text => /no activity/i)
    end

  end

end
