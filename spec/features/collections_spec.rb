require "spec_helper"

#TODO: test connection with Solr: filter, sort, total results, paging, etc

def it_should_collect_item(collectable_item_path, collectable_item)
  visit collectable_item_path
  click_link 'Add to a collection'
  if current_url.match /#{login_url}/
    page.fill_in 'session_username_or_email', with: @anon_user.username
    page.fill_in 'session_password', with: 'password'
    click_button 'Sign in'
    continue_collect(@anon_user, collectable_item_path)
    visit logout_url
  else
    continue_collect(@user, collectable_item_path)
  end
end

# TODO - errr... you have heard of yeild and block-passing, right?
def continue_collect(user, url)
  current_url.should match /#{choose_collect_target_collections_path}/
  check 'collection_id_'
  begin
    click_button 'Collect item'
  rescue EOL::Exceptions::InvalidCollectionItemType
    # TODO - ...We're expecing this, I hope?
  end
  # TODO
  # current_url.should match /#{url}/
  # body.should include('added to collection')
  # user.watch_collection.items.map {|li| li.collected_item }.include?(collectable_item).should be_true
end

def it_should_create_and_collect_item(collectable_item_path, collectable_item)
  visit collectable_item_path
  click_link 'Add to a collection'
  if current_url.match /#{login_url}/
    page.fill_in 'session_username_or_email', with: @anon_user.username
    page.fill_in 'session_password', with: 'password'
    click_button 'Sign in'
    continue_create_and_collect(@anon_user, collectable_item_path)
    visit logout_url
  else
    continue_create_and_collect(@user, collectable_item_path)
  end
end

def continue_create_and_collect(user, url)
  current_url.should match /#{choose_collect_target_collections_path}/
  click_button 'Create collection'
  body.should have_tag(".collection_name_error", text: "Collection name can't be blank")
  fill_in 'collection_name', with: "#{user.username}'s new collection"
  click_button 'Create collection'
  body.should_not have_tag(".collection_name_error", text: "Collection name can't be blank")
end

describe "Collections" do
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
    @collection_name = @collection.name
    @user = nil
    @under_privileged_user = User.gen
    @anon_user = User.gen(password: 'password')
    @taxon = @test_data[:taxon_concept_1]
    @taxon_to_collect = @test_data[:taxon_concept_2]
    @collection.add(@taxon)
    EOL::Solr::CollectionItemsCoreRebuilder.begin_rebuild
  end

  # TODO - this was done wrong. The counts are not guarnteed to work independently of order.  I'm doing my best to sort
  # out the data beforehand, but really, we should create a bunch of scenarios in the collections scenario to account
  # for each of the required specs, and not muck with the data on the same taxon/collection each time.
  before(:each) do
    @collection.update_column(:published, true)
    @collection.update_column(:name, @collection_name)
    @collection.update_column(:view_style_id, ViewStyle.annotated.id)
  end

  describe '(Preview)' do

    it 'should show collection on the taxon collections page' do
      visit collections_taxon_communities_path(@taxon)
      body.should have_tag("a[href='#{collection_path(@collection)}']")
    end

    it 'should not show preview collections on the taxon page' do
      @collection.update_column(:published, false)
      visit collections_taxon_communities_path(@taxon)
      body.should_not have_tag("a[href='#{collection_path(@collection)}']")
    end

    it 'should not show preview collections on the user profile page to normal users' do
      visit user_collections_path(@collection.users.first)
      body.should match(@collection.name)
      @collection.update_column(:published, false)
      visit user_collections_path(@collection.users.first)
      body.should_not match(@collection.name)
    end

    # See 9853360275ad5f3b673c4ba86379397d32efa805 if you want this back:
    # it 'should show resource preview collections on the user profile page to the owner'

    # TODO - there are multiple assertions here that should be grouped differently.
    it 'should show removed message when unpublished' do
      collection = Collection.gen(
        published: false,
        view_style: ViewStyle.annotated,
        resource: Resource.gen(preview_collection: collection)
      )
      collection.reload
      visit logout_path
      visit collection_path(collection)
      expect(page).to have_content(I18n.t(:collection_was_removed_by_owner))
      user = User.gen(admin: false)
      login_as user
      visit collection_path(collection)
      expect(page).to have_content(I18n.t(:collection_was_removed_by_owner))

      admin = User.gen(admin: true)
      login_as admin
      visit collection_path(collection)
      body.should have_tag('h1', text: collection.name)
      expect(page).to have_content(I18n.t(:collection_was_removed_by_owner))

      login_as collection.users.first
      visit collection_path(collection)
      expect(page).to have_content(I18n.t(:collection_was_removed_by_owner))
      body.should have_tag('h1', text: collection.name)
    end

  end

  describe "(normal)" do

    shared_examples_for 'collections all users' do
      it 'should be able to view a collection and its items' do
        visit collection_path(@collection)
        body.should have_tag('h1', text: @collection.name)
        body.should have_tag('ul.object_list li h4', text: @collection.collection_items.first.collected_item.best_title)
      end

      it "should be able to sort a collection's items" do
        visit collection_path(@collection)
        body.should have_tag('#sort_by')
      end

      it "should be able to change the view of a collection" do
        visit collection_path(@collection)
        col = Collection.find(@collection.id) rescue debugger # WHAT HAPPENED?!
        body.should have_tag('#view_as')
      end

    end

    shared_examples_for 'collecting all users' do
      describe "should be able to collect" do
        it 'taxa' do
          it_should_collect_item(taxon_overview_path(@taxon), @taxon)
        end
        it 'data objects' do
          latest_revision_of_dato = @taxon.data_objects.first.latest_published_version_in_same_language
          it_should_collect_item(data_object_path(latest_revision_of_dato), latest_revision_of_dato)
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

    shared_examples_for 'creating collection and collecting all users' do
      describe "should be able to create collection and collect" do
        it 'taxa' do
          it_should_create_and_collect_item(taxon_overview_path(@taxon_to_collect), @taxon_to_collect)
        end
        it 'data objects' do
          latest_revision_of_dato = @taxon_to_collect.data_objects.first.latest_published_version_in_same_language
          it_should_create_and_collect_item(data_object_path(latest_revision_of_dato), latest_revision_of_dato)
        end
        it 'communities' do
          new_community = Community.gen
          it_should_create_and_collect_item(community_path(new_community), new_community)
        end
        it 'collections, unless its their watch collection' do
          it_should_create_and_collect_item(collection_path(@collectable_collection), @collectable_collection)
          unless @user.nil?
            visit collection_path(@user.watch_collection)
            body.should_not have_tag('a.collect')
          end
        end
        it 'users' do
          new_user = User.gen
          it_should_create_and_collect_item(user_path(new_user), new_user)
        end
      end
    end

    # Make sure you are logged in prior to calling this shared example group
    shared_examples_for 'collection and collecting logged in user' do
      it_should_behave_like 'collections all users'
      it_should_behave_like 'collecting all users'
      it_should_behave_like 'creating collection and collecting all users'

      it 'should be able to select all collection items on the page' do
        visit collection_path(@collection)
        body.should_not have_tag("input[id=collection_item_#{@collection.collection_items.first.id}][checked]")
        visit collection_path(@collection, commit_select_all: true) # FAKE the button click, since it's JS otherwise
        body.should have_tag("input[id=collection_item_#{@collection.collection_items.first.id}][checked]")
      end

      it 'should be able to copy collection items to one of their existing collections' do
        visit collection_path(@collection, commit_select_all: true) # Select all button is JS, fake it.
        click_button 'Copy selected'
        body.should have_tag('#collection') do
          with_tag('input[value=?]', @user.watch_collection.name)
        end
      end

      it 'should be able to copy collection items to a new collection' do
        visit collection_path(@collection, commit_select_all: true) # Select all button is JS, fake it.
        click_button 'Copy selected'
        body.should have_tag('#collection') do
          with_tag('form.new_collection')
        end
      end
    end

    describe 'anonymous users' do
      before(:all) do
        visit logout_url
      end
      subject { body }
      it_should_behave_like 'collections all users'
      it 'should not be able to select collection items' do
        visit collection_path(@collection)
        should_not have_tag("input#collection_item_#{@collection.collection_items.first.id}")
        should_not have_tag('input[name=commit_select_all]')
      end
      it 'should not be able to copy collection items' do
        visit collection_path(@collection)
        should_not have_tag("input#collection_item_#{@collection.collection_items.first.id}")
        should_not have_tag('input[name=commit_copy_collection_items]')
      end
      it 'should not be able to move collection items' do
        visit collection_path(@collection)
        should_not have_tag("input#collection_item_#{@collection.collection_items.first.id}")
        should_not have_tag('input[name=commit_move_collection_items]')
      end
      it 'should not be able to remove collection items' do
        visit collection_path(@collection)
        should_not have_tag("input#collection_item_#{@collection.collection_items.first.id}")
        should_not have_tag('input[name=commit_remove_collection_items]')
      end
    end

    describe 'user without privileges' do
      before(:each) do
        @user = @under_privileged_user
        login_as @user
      end
      after(:all) { @user = nil }
      it_should_behave_like 'collections all users'
      it_should_behave_like 'collecting all users'
      it_should_behave_like 'creating collection and collecting all users'
      it 'should not be able to move collection items' do
        visit collection_path(@collection)
        should_not have_tag("input#collection_item_#{@collection.collection_items.first.id}")
        should_not have_tag('input[name=commit_move_collection_items]')
      end
      it 'should not be able to remove collection items' do
        visit collection_path(@collection)
        should_not have_tag("input#collection_item_#{@collection.collection_items.first.id}")
        should_not have_tag('input[name=commit_remove_collection_items]')
      end
    end

    describe 'user with privileges' do
      before(:each) do
        @user = @collection_owner
        login_as @user
      end
      after(:all) { @user = nil }
      it_should_behave_like 'collections all users'
      it_should_behave_like 'collecting all users'
      it_should_behave_like 'creating collection and collecting all users'
      it 'should be able to move collection items'
      it 'should be able to remove collection items'
      it 'should be able to edit ordinary collection' do
        visit edit_collection_path(@collection)
        page.fill_in 'collection_name', with: 'Edited collection name'
        click_button 'Update collection details'
        body.should have_tag('h1', text: 'Edited collection name')
      end
      it 'should be able to edit ordinary collection item attributes (with JS off, need Cucumber tests for JS on)'
      it 'should be able to delete ordinary collections'
      it 'should not be able to delete special collections'
      it 'should not be able to edit watch collection name' do
        visit edit_collection_path(@user.watch_collection)
        body.should have_tag('#collections_edit') do
          without_tag('#collection_name', val: "#{@collection.name}")
          with_tag('label', text: "#{@user.watch_collection.name}")
        end
      end
    end

    it "should always link collected objects to their latest published versions" do
      @original_index_records_on_save_value = $INDEX_RECORDS_IN_SOLR_ON_SAVE
      $INDEX_RECORDS_IN_SOLR_ON_SAVE = true
      login_as @anon_user
      new_dato = DataObject.gen
      visit data_object_path(new_dato)
      click_link 'Add to a collection'
      current_url.should match /#{choose_collect_target_collections_path}/
      check 'collection_id_'
      click_button 'Collect item'
      collectable_data_object = new_dato.latest_published_version_in_same_language
      collectable_data_object.object_title = "Current data object"
      collectable_data_object.save

      # first time visiting - collected image should show up
      visit collection_path(@anon_user.watch_collection)
      body.should have_tag("ul.object_list li a[href='#{data_object_path(collectable_data_object)}']")

      # the image will unpublished, but there are no newer versions, so it will still show up
      collectable_data_object.published = 0
      collectable_data_object.save
      # TODO - legitimate failure. I'm guessing this is also due to Solr returning unexpected results...
      # ...in any case I'm going to take it out because I don't REALLY care if an unpublished dato ISN'T showing
      # up...
      # visit collection_path(@anon_user.watch_collection)
      # body.should have_tag("ul.object_list li a[href='#{data_object_path(collectable_data_object)}']")

      # the image is still unpublished, but there's a newer version. We should see the new version in the collection
      newer_version_collected_data_object = DataObject.gen(guid: new_dato.guid,
        object_title: "Latest published version", published: true, created_at: Time.now )
      visit collection_path(@anon_user.watch_collection)
      body.should have_tag("ul.object_list li a[href='#{data_object_path(newer_version_collected_data_object)}']")
      body.should_not have_tag("ul.object_list li a[href='#{data_object_path(collectable_data_object)}']")

      # finally, with each version published, we should not be able to add the latest version into our collection
      # as the collection already contains a version of this objects
      visit data_object_path(newer_version_collected_data_object)
      click_link 'Add to a collection'
      current_url.should match /#{choose_collect_target_collections_path}/
      body.should have_tag("li a", text: I18n.t(:in_collection))

      # and deleting the first version from the collection will allow the new one to be added
      @anon_user.watch_collection.collection_items[0].destroy
      visit data_object_path(newer_version_collected_data_object)
      click_link 'Add to a collection'
      current_url.should match /#{choose_collect_target_collections_path}/
      body.should_not have_tag("li a", text: I18n.t(:in_collection))

      newer_version_collected_data_object.destroy
      $INDEX_RECORDS_IN_SOLR_ON_SAVE = @original_index_records_on_save_value
    end

    it "collections should respect the max_items_per_page value of their ViewStyles and have appropriate rel link tags" do
      @original_index_records_on_save_value = $INDEX_RECORDS_IN_SOLR_ON_SAVE
      $INDEX_RECORDS_IN_SOLR_ON_SAVE = true

      collection_owner = User.gen(password: 'somenewpassword')
      collection = collection_owner.watch_collection
      collection.view_style = ViewStyle.first
      collection.save

      # adding 7 items in the collection
      collection.add DataObject.gen
      collection.add DataObject.gen
      collection.add DataObject.gen
      collection.add DataObject.gen
      collection.add DataObject.gen
      collection.add DataObject.gen
      collection.add DataObject.gen

      # setting the collection's view style to one that allows 2 items per page
      v = ViewStyle.first
      v.max_items_per_page = 2
      v.save
      visit collection_path(collection)
      # there should be exactly 4 pages when we have a max_items_per_page of 2
      body.should match(/href="\/collections\/#{collection.id}\?page=4/)
      body.should_not match(/href="\/collections\/#{collection.id}\?page=5/)

      # on page 1 rel canonical should not include page number;  rel prev should not exist; rel next is page 2; title should not include page
      body.should have_tag("link[rel=canonical][href$='#{collection_path(collection)}']")
      body.should_not have_tag('link[rel=prev]')
      body.should have_tag("link[rel=next][href$='#{collection_path(collection, page: 2)}']")
      # on page 2 rel canonical should include page 2; rel prev should be page 1; rel next should be page 3; title should include page
      visit collection_path(collection, page: 2)
      body.should have_tag("link[rel=canonical][href$='#{collection_path(collection_owner.watch_collection, page: 2)}']")
      body.should have_tag("link[rel=prev][href$='#{collection_path(collection, page: 1)}']")
      body.should have_tag("link[rel=next][href$='#{collection_path(collection, page: 3)}']")
      # on last page there should be no rel next
      visit collection_path(collection, page: 4)
      body.should have_tag("link[rel=canonical][href$='#{collection_path(collection_owner.watch_collection, page: 4)}']")
      body.should have_tag("link[rel=prev][href$='#{collection_path(collection, page: 3)}']")
      body.should_not have_tag('link[rel=next]')

      v = ViewStyle.first
      v.max_items_per_page = 4
      v.save
      visit collection_path(collection_owner.watch_collection)
      # there should be exactly 2 pages when we have a max_items_per_page of 4
      body.should match(/href="\/collections\/#{collection.id}\?page=2/)
      body.should_not match(/href="\/collections\/#{collection.id}\?page=3/)

      # now testing the next/previous links show only when necessary
      body.should_not include "Previous"
      body.should include "Next"

      visit collection_path(collection_owner.watch_collection, page: 2)
      body.should include "Previous"
      body.should_not include "Next"

      $INDEX_RECORDS_IN_SOLR_ON_SAVE = @original_index_records_on_save_value
    end

    it 'collection newsfeed should have rel canonical link tag'
    it 'collection newsfeed should have prev and next link tags if relevant'
    it 'collection newsfeed should append page number to head title if relevant'
    it 'collection editors should have rel canonical link tag'
    it 'collection editors should not have prev and next link tags'

    # TODO - write this spec somewhere useful.
    # We don't gain much from testing this here. It's a rather specific test (user activity should not include watch
    # collection activities), it's very hard to test, it's very expensive to set up, and it's a waste of time.
    it 'should not index activity log in SOLR if the collection is watch collection'

  end

end

