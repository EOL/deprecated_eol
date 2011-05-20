require 'spec_helper'

def test_list_of_items(instance)
  posts = []
  3.times { posts << Faker::Lorem.words(1)[0] }
  posts.each {|p| instance.feed.post p }
  visit feed_items_path(:type => instance.class.name, :id => instance.id)
  posts.each {|p| page.body.should have_tag('.details', /#{p}/) }
end

describe "FeedItems" do

  before(:all) do
    truncate_all_tables
    load_foundation_cache
    Capybara.reset_sessions!
    @user = User.gen
  end

  it 'should list all of the items in a feed for a user' do
    test_list_of_items(@user)
  end

  it 'should require log in to add an item to a feed' do
    visit feed_items_path(:type => 'User', :id => @user.id)
    page.body.should_not have_tag('input#feed_item_body')
    page.body.should have_tag('a[href=?]', /\/login.*/)
  end

  it 'should allow adding an item to a feed for a user when logged in' do
    login_as @user
    visit feed_items_path(:type => 'User', :id => @user.id)
    page.body.should have_tag('input#feed_item_body')
    page.body.should_not have_tag('a.login_link')
    visit logout_url
  end

  it 'should allow a user with privileges to remove a feed item from feed for a user'
  it 'should NOT allow a user WITHOUT privileges to remove a feed item from feed for a user'

  it 'should allow a user to edit a feed item created by that user'
  it 'should NOT allow a user to edit a feed item created by another user'

  it 'should allow a user to remove a feed item created by that user'
  it 'should NOT allow a user to remove a feed item created by another user'

end
