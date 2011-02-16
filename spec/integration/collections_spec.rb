require File.dirname(__FILE__) + '/../spec_helper'

describe "Collections controller" do

  before(:all) do
    truncate_all_tables
    load_foundation_cache
    Capybara.reset_sessions!
    @user = User.gen
    @user2 = User.gen # This user is very likeable.
    @taxon_concept = build_taxon_concept(:images => [{}]) # One image
    @image = @taxon_concept.images.first
    @community = Community.gen
    @collection = Collection.gen
  end

  describe "(logged in)" do

    before(:all) do
      login_as @user
    end

    describe "should allow users to watch" do

      it 'taxa' do
        visit watch_path(:type => 'TaxonConcept', :id => @taxon_concept.id)
        @user.watch_collection.items.map {|li| li.object }.include?(@taxon_concept).should be_true
      end

      it 'data objects' do
        visit watch_path(:type => 'DataObject', :id => @image.id)
        @user.watch_collection.items.map {|li| li.object }.include?(@image).should be_true
      end

      it 'communities' do
        visit watch_path(:type => 'Community', :id => @community.id)
        @user.watch_collection.items.map {|li| li.object }.include?(@community).should be_true
      end

      it 'collections' do
        visit watch_path(:type => 'Collection', :id => @collection.id)
        @user.watch_collection.items.map {|li| li.object }.include?(@collection).should be_true
      end

      it 'users' do
        visit watch_path(:type => 'User', :id => @user2.id)
        @user.watch_collection.items.map {|li| li.object }.include?(@user2).should be_true
      end

    end

    describe "should allow users to collect" do

      it 'taxa' do
        visit collect_path(:type => 'TaxonConcept', :id => @taxon_concept.id)
        @user.inbox_collection.items.map {|li| li.object }.include?(@taxon_concept).should be_true
      end

      it 'data objects' do
        visit collect_path(:type => 'DataObject', :id => @image.id)
        @user.inbox_collection.items.map {|li| li.object }.include?(@image).should be_true
      end

      it 'communities' do
        visit collect_path(:type => 'Community', :id => @community.id)
        @user.inbox_collection.items.map {|li| li.object }.include?(@community).should be_true
      end

      it 'collections' do
        visit collect_path(:type => 'Collection', :id => @collection.id)
        @user.inbox_collection.items.map {|li| li.object }.include?(@collection).should be_true
      end

      it 'users' do
        visit collect_path(:type => 'User', :id => @user2.id)
        @user.inbox_collection.items.map {|li| li.object }.include?(@user2).should be_true
      end

    end

    describe "#show" do

      before(:all) do
        @show_user = User.gen
        @show_collection = Collection.gen(:user => @show_user)
        @show_items = []
        @show_items[0] = @show_collection.add(@shown_taxon_concept = build_taxon_concept(:images => [{}]))
        @show_items[1] = @show_collection.add(@shown_image = @taxon_concept.images.first)
        @show_items[2] = @show_collection.add(@shown_community = Community.gen)
        @show_items[3] = @show_collection.add(@shown_collection = Collection.gen)
      end

      describe "(NOT editable)" do

        before(:all) do 
          visit logout_url
          visit collection_path(@show_collection)
        end

        it 'should NOT have a select box for each collection item' do
          page.body.should_not have_tag("input#collection_items[type=checkbox][value=?]", @show_collection.items.first.id)
        end

        it 'should NOT allow users to delete collections' do
          page.body.should_not have_tag("a[href=?]", collection_path(@show_collection), :text => /delete/i)
        end

        it 'should allow users to edit the name of specific collections' do
          page.body.should_not have_tag(".actions a", :text => /change name/i)
          page.body.should_not have_tag("input#collection_name")
        end

      end

      describe "(editable)" do

        before(:all) do
          login_as @show_user
        end

        before(:each) do
          visit collection_path(@show_collection)
        end

        it 'should show all the items in a collection' do
          page.body.should have_tag("a[href=?]", taxon_concept_path(@shown_taxon_concept))
          page.body.should have_tag("a[href=?]", data_object_path(@shown_image))
          page.body.should have_tag("a[href=?]", community_path(@shown_community))
          page.body.should have_tag("a[href=?]", collection_path(@shown_collection))
        end

        it 'should have a select box for each collection item' do
          page.body.should have_tag("input#collection_items[type=checkbox][value=?]", @show_collection.items.first.id)
        end

        # NOTE - this is just a view test.  We should actually delete a collection, but that requires JS.
        it 'should allow users to delete specific collections' do
          page.body.should have_tag("a[href=?]", collection_path(@show_collection), :text => /delete/i)
        end

        # NOTE - this is just a view test.  We should actually rename the collection, but that requires JS.
        it 'should allow users to edit the name of specific collections' do
          page.body.should have_tag(".actions") do
            with_tag('a', :text => 'Change Name')
          end
          page.body.should have_tag("input#collection_name")
        end

      end

    end

    it 'should allow users with privileges to copy selected collection items to another one of their collections'

    it 'should allow users with privileges to create collections from selected collection items'

    it 'should allow users with privileges to remove collection items'

    it 'should NOT allow users WITHOUT privileges to remove collection items'

    it 'should NOT allow users to rename or delete "task" collections' do
      login_as @user
      visit community_path(@user.task_collection)
      page.body.should_not have_tag("a[href=?]", collection_path(@user.task_collection), :text => /delete/i)
      page.body.should_not have_tag("a", :text => /change name/i)
      page.body.should_not have_tag("input#collection_name")
    end

    it 'should NOT allow users to rename or delete "watch" collections' do
      login_as @user
      visit community_path(@user.watch_collection)
      page.body.should_not have_tag("a[href=?]", collection_path(@user.watch_collection), :text => /delete/i)
      page.body.should_not have_tag("a", :text => /change name/i)
      page.body.should_not have_tag("input#collection_name")
    end

    # TODO... we don't have tasks yet.
    it 'should allow users to add tasks to their task collection'

  end

end
