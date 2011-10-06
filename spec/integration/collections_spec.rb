require File.dirname(__FILE__) + '/../spec_helper'

def it_should_collect_item(collectable_item_path, collectable_item)
  visit collectable_item_path
  click_link 'Add to a collection'
  if current_url.match /#{login_url}/
    page.fill_in 'session_username_or_email', :with => @anon_user.username
    page.fill_in 'session_password', :with => 'password'
    click_button 'Sign in'
    continue_collect(@anon_user, collectable_item_path)
    visit logout_url
  else
    continue_collect(@user, collectable_item_path)
  end
end

def continue_collect(user, url)
  current_url.should match /#{choose_collect_target_collections_path}/
  check 'collection_id_'
  click_button 'Collect item'
  # TODO
  #current_url.should match /#{url}/
  #body.should include('added to collection')
  #user.watch_collection.items.map {|li| li.object }.include?(collectable_item).should be_true
end

describe "Collections and collecting:" do

  before(:all) do
    # so this part of the before :all runs only once
    unless User.find_by_username('collections_scenario')
      truncate_all_tables
      load_scenario_with_caching(:collections)
    end
    Capybara.reset_sessions!
    @test_data = EOL::TestInfo.load('collections')
    @collectable_collection = Collection.gen
    @collection = @test_data[:collection]
    @collection_owner = @test_data[:user]
    @user = nil
    @under_privileged_user = User.gen
    @anon_user = User.gen(:password => 'password')
    @taxon = @test_data[:taxon_concept_1]
    builder = EOL::Solr::CollectionItemsCoreRebuilder.new()
    builder.begin_rebuild
  end

  shared_examples_for 'collections all users' do
    it 'should be able to view a collection and its items' do
      visit collection_path(@collection)
      body.should have_tag('h1', /#{@collection.name}/)
      body.should have_tag('ul.object_list li', /#{@collection.collection_items.first.object.best_title}/)
    end

    it "should be able to sort a collection's items" do
      visit collection_path(@collection)
      body.should have_tag('#sort_by')
    end
  end

  shared_examples_for 'collecting all users' do
    describe "should be able to collect" do
      it 'taxa' do
        it_should_collect_item(taxon_overview_path(@taxon), @taxon)
      end
      it 'data objects' do
        it_should_collect_item(data_object_path(@taxon.images.first), @taxon.images.first)
      end
      it 'communities' do
        new_community = Community.gen
        it_should_collect_item(community_path(new_community), new_community)
      end
      it 'collections, unless its their watch collection' do
        it_should_collect_item(collection_path(@collectable_collection), @collectable_collection)
        unless @user.nil?
          visit collection_path(@user.watch_collection)
          body.should_not have_tag('a.collect')
        end
      end
      it 'users' do
        new_user = User.gen
        it_should_collect_item(user_path(new_user), new_user)
      end
    end
  end

  # Make sure you are logged in prior to calling this shared example group
  shared_examples_for 'collections and collecting logged in user' do
    it_should_behave_like 'collections all users'
    it_should_behave_like 'collecting all users'

    it 'should be able to select all collection items on the page' do
      visit collection_path(@collection)
      body.should_not have_tag("input[id=?][checked]", "collection_item_#{@collection.collection_items.first.id}")
      visit collection_path(@collection, :commit_select_all => true) # FAKE the button click, since it's JS otherwise
      body.should have_tag("input[id=?][checked]", "collection_item_#{@collection.collection_items.first.id}")
    end

    it 'should be able to copy collection items to one of their existing collections' do
      visit collection_path(@collection, :commit_select_all => true) # Select all button is JS, fake it.
      click_button 'Copy selected'
      body.should have_tag('#collections') do
        with_tag('input[value=?]', @user.watch_collection.name)
      end
    end

    it 'should be able to copy collection items to a new collection' do
      visit collection_path(@collection, :commit_select_all => true) # Select all button is JS, fake it.
      click_button 'Copy selected'
      body.should have_tag('#collections') do
        with_tag('form.new_collection')
      end
    end
  end

  describe 'anonymous users' do
    before(:all) { visit logout_url }
    subject { body }
    it_should_behave_like 'collections all users'
    # it_should_behave_like 'collecting all users'
    it 'should not be able to select collection items' do
      visit collection_path(@collection)
      should_not have_tag("input#collection_item_#{@collection.collection_items.first.id}")
      should_not have_tag('input[name=?]', 'commit_select_all')
    end
    it 'should not be able to copy collection items' do
      visit collection_path(@collection)
      should_not have_tag("input#collection_item_#{@collection.collection_items.first.id}")
      should_not have_tag('input[name=?]', 'commit_copy_collection_items')
    end
    it 'should not be able to move collection items' do
      visit collection_path(@collection)
      should_not have_tag("input#collection_item_#{@collection.collection_items.first.id}")
      should_not have_tag('input[name=?]', 'commit_move_collection_items')
    end
    it 'should not be able to remove collection items' do
      visit collection_path(@collection)
      should_not have_tag("input#collection_item_#{@collection.collection_items.first.id}")
      should_not have_tag('input[name=?]', 'commit_remove_collection_items')
    end
  end

  describe 'user without privileges' do
    before(:all) {
      @user = @under_privileged_user
      login_as @user
    }
    after(:all) { @user = nil }
    it_should_behave_like 'collections all users'
    it_should_behave_like 'collecting all users'
    it 'should not be able to move collection items' do
      visit collection_path(@collection)
      should_not have_tag("input#collection_item_#{@collection.collection_items.first.id}")
      should_not have_tag('input[name=?]', 'commit_move_collection_items')
    end
    it 'should not be able to remove collection items' do
      visit collection_path(@collection)
      should_not have_tag("input#collection_item_#{@collection.collection_items.first.id}")
      should_not have_tag('input[name=?]', 'commit_remove_collection_items')
    end
  end

  describe 'user with privileges' do
    before(:all) {
      @user = @collection_owner
      login_as @user
    }
    after(:all) { @user = nil }
    it_should_behave_like 'collections all users'
    it_should_behave_like 'collecting all users'
    it 'should be able to move collection items'
    it 'should be able to remove collection items'
    it 'should be able to edit ordinary collection and nested collection item attributes' do
      visit edit_collection_path(@collection)
      page.fill_in 'collection_name', :with => 'Edited collection name'
      click_button 'Update collection details'
      body.should have_tag('h1', 'Edited collection name')
    end
    it 'should be able to delete ordinary collections'
    it 'should not be able to delete special collections'
    it 'should not be able to edit watch collection name' do
      visit edit_collection_path(@collection)
      body.should have_tag('#collections_edit') do
        with_tag('#collection_name', :val => "#{@collection.name}")
        without_tag('label', :text => "#{@user.watch_collection.name}")
      end
      visit edit_collection_path(@user.watch_collection)
      body.should have_tag('#collections_edit') do
        without_tag('#collection_name', :val => "#{@collection.name}")
        with_tag('label', :text => "#{@user.watch_collection.name}")
      end
    end
  end

end



describe "Preview Collections" do
  before(:all) do
    unless User.find_by_username('collections_scenario')
      truncate_all_tables
      load_scenario_with_caching(:collections)
    end
    Capybara.reset_sessions!
    @test_data = EOL::TestInfo.load('collections')
    @collectable_collection = Collection.gen
    @collection = @test_data[:collection]
    @collection_owner = @test_data[:user]
    @user = nil
    @under_privileged_user = User.gen
    @anon_user = User.gen(:password => 'password')
    @taxon = @test_data[:taxon_concept_1]
    @collection.add(@taxon)
    builder = EOL::Solr::CollectionItemsCoreRebuilder.new()
    builder.begin_rebuild
  end

  it 'should show collections on the taxon page' do
    visit taxon_path(@taxon)
    body.should have_tag('#collections_summary') do
      with_tag('h3', :text => "Present in 1 collection")
    end
  end

  it 'should not show preview collections on the taxon page' do
    @collection.update_attribute(:published, false)
    visit taxon_path(@taxon)
    body.should have_tag('#collections_summary') do
      with_tag('h3', :text => "Present in 0 collections")
    end
    @collection.update_attribute(:published, true)
  end

  it 'should not show preview collections on the user profile page to normal users' do
    visit user_collections_path(@collection.user)
    body.should have_tag('li.active') do
      with_tag('a', :text => "3 collections")
    end
    body.should have_tag('h3', :text => "2 collections")
    @collection.update_attribute(:published, false)
    visit user_collections_path(@collection.user)
    body.should have_tag('li.active') do
      with_tag('a', :text => "2 collections")
    end
    body.should have_tag('div.heading') do
      with_tag('h3', :text => "1 collection")
    end
    @collection.update_attribute(:published, true)
  end

  it 'should show resource preview collections on the user profile page to the owner' do
    @collection.update_attribute(:published, false)
    @resource = Resource.gen
    @resource.preview_collection = @collection
    @resource.save
    login_as @collection.user
    visit user_collections_path(@collection.user)
    body.should have_tag('li.active') do
      with_tag('a', :text => "3 collections")
    end
    body.should have_tag('div.heading') do
      with_tag('h3', :text => "2 collections")
    end
    visit('/logout')
    @collection.update_attribute(:published, true)
  end

  it 'should allow EOL administrators to view unpublished collections' # do
#    @collection.update_attribute(:published, false)
#    @resource = Resource.gen
#    @resource.preview_collection = @collection
#    @resource.save
#    visit('/logout')
#    visit collection_path(@collection)
#    current_url.should_not == collection_url(@collection)
#    body.should_not have_tag('h1', /#{@collection.name}/)
#    admin = User.gen(:admin => true)
#    login_as admin
#    visit collection_path(@collection)
#    body.should have_tag('h1', /#{@collection.name}/)
#    body.should have_tag('ul.object_list li', /#{@collection.collection_items.first.object.best_title}/)
#    @collection.update_attribute(:published)
#  end
end

#TODO: test connection with Solr: filter, sort, total results, paging, etc
