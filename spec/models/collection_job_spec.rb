require File.dirname(__FILE__) + '/../spec_helper'

describe CollectionJob do

  # TODO - custom matcher
  def collection_should_include(collection, item)
    collection.collection_items.reload.map(&:collected_item).should include(item)
  end
  def collection_should_not_include(collection, item)
    collection.collection_items.reload.map(&:collected_item).should_not include(item)
  end

  def all_item_job(command)
    CollectionJob.new(command: command, user: @user, collection: @source, collections: [@target], all_items: true)
  end

  before(:all) do
    @old_val = $INDEX_RECORDS_IN_SOLR_ON_SAVE
    $INDEX_RECORDS_IN_SOLR_ON_SAVE = true # Nothing happens otherwise.
    Visibility.create_enumerated
    DataType.create_enumerated
    License.create_enumerated
    entry = HierarchyEntry.gen # Gives the TC a name.
    @tc = entry.taxon_concept
    @user = User.gen
    @has_source_but_not_target = User.gen
    @has_target_but_not_source = User.gen
    @dato = DataObject.gen(:object_title => 'Image of your mom')
    @person = User.gen
    @source = Collection.gen
    @target = Collection.gen
    @collection = Collection.gen
    @user.collections = [@source, @target]
    @has_source_but_not_target.collections << @source
    @has_target_but_not_source.collections << @target
    @source_tc_annotation = 'source tc annotation'
    @source_tc_refs = [Ref.gen, Ref.gen]
    @source_tc_sort = 'concept sorter'
    @source_collection_annotation = 'source collection annotation'
    @source_collection_refs = [Ref.gen, Ref.gen]
    @source_collection_sort = 'collection sorter'
  end

  after(:all) do
    $INDEX_RECORDS_IN_SOLR_ON_SAVE = @old_val
  end

  # This looks like a lot of setup, but it's actually really simple stuff; don't be intimidated. Collections have
  # lots of items, and items can be complicated!  :)
  before(:each) do
    CollectionItem.delete_all
    @source_tc = CollectionItem.create(collected_item: @tc, name: 'unused', collection: @source,
                                       added_by_user: @user, annotation: @source_tc_annotation,
                                       refs: @source_tc_refs, sort_field: @source_tc_sort)
    @source_dato = CollectionItem.create(collected_item: @dato, name: 'unused', collection: @source,
                                         added_by_user: @user)
    @source_collection = CollectionItem.create(collected_item: @collection, name: 'unused', collection: @source,
                                               added_by_user: @user, annotation: @source_collection_annotation,
                                               refs: @source_collection_refs, sort_field: @source_collection_sort)
    CollectionItem.create(collected_item: @person, name: 'unused', collection: @source, added_by_user: @user)

    CollectionItem.create(collected_item: @tc, name: 'unused', collection: @target, added_by_user: @user)
    CollectionItem.create(collected_item: @dato, name: 'unused', collection: @target, added_by_user: @user)

    # The following assuptions are used in multiple specs, so we check them universally:
    @source.reload
    @target.reload
  end

  it 'should copy from one collection to another without copying duplicates' do
    job = CollectionJob.new(command: 'copy', user: @user, collection: @source, collections: [@target],
                            collection_item_ids: [@source_tc.id, @source_dato.id, @source_collection.id])
    job.run
    @source.reload.collection_items.count.should == 4 # nothing got removed?
    @target.reload.collection_items.count.should == 3 # only one thing was added?
    collection_should_include(@target, @collection)
    job.item_count.should == 1 # Because only one of the four actually got copied.
  end

  it 'should move from one collection to another without moving duplicates' do
    job = CollectionJob.new(command: 'move', user: @user, collection: @source, collections: [@target],
                            collection_item_ids: [@source_tc.id, @source_dato.id, @source_collection.id])
    job.run
    @source.reload.collection_items.count.should == 3 # only one thing should actually have moved.
    @target.reload.collection_items.count.should == 3 # only one thing was added?
    collection_should_include(@source, @tc) # Dupe, should have stayed.
    collection_should_include(@source, @dato) # Dupe, should have stayed.
    collection_should_not_include(@source, @collection)
    collection_should_include(@target, @tc)
    collection_should_include(@target, @dato)
    collection_should_include(@target, @collection)
    job.item_count.should == 1
  end

  it 'should remove items from a collection' do
    job = CollectionJob.new(command: 'remove', user: @user, collection: @source,
                            collection_item_ids: [@source_tc.id, @source_dato.id, @source_collection.id])
    job.run
    @source.reload.collection_items.count.should == 1
    collection_should_include(@source, @person)
    collection_should_not_include(@source, @tc)
    collection_should_not_include(@source, @dato)
    collection_should_not_include(@source, @collection)
    job.item_count.should == 3
  end

  # NOTE - all_items uses different algorithms, and we want to ensure they still work, so they are tested separately:
  it 'should copy all items from one collection to another without copying duplicates' do
    job = all_item_job('copy')
    job.run
    @source.reload.collection_items.count.should == 4 # nothing got removed?
    @target.reload.collection_items.count.should == 4
    collection_should_include(@target, @collection)
    collection_should_include(@target, @person)
    job.item_count.should == 2
  end

  it 'should move all items from one collection to another without moving duplicates' do
    job = all_item_job('move')
    job.run
    @source.reload.collection_items.count.should == 2
    @target.reload.collection_items.count.should == 4
    collection_should_include(@source, @tc) # Dupe, should have stayed.
    collection_should_include(@source, @dato) # Dupe, should have stayed.
    collection_should_not_include(@source, @collection)
    collection_should_not_include(@source, @person)
    collection_should_include(@target, @tc)
    collection_should_include(@target, @dato)
    collection_should_include(@target, @collection)
    collection_should_include(@target, @person)
    job.item_count.should == 2 # Failing, getting 3, but only two moved...
  end

  it 'should remove all items items from a collection' do
    job = all_item_job('remove')
    job.run
    @source.reload.collection_items.count.should == 0
    collection_should_not_include(@source, @person)
    collection_should_not_include(@source, @tc)
    collection_should_not_include(@source, @dato)
    collection_should_not_include(@source, @collection)
    job.item_count.should == 4
  end

  it 'should copy attribution and references if user owns both collections' do
    CollectionJob.new(command: 'copy', user: @user, collection: @source, collections: [@target],
                      collection_item_ids: [@source_collection.id]).run
    target_collection = @target.select_item(@collection)
    target_collection.annotation.should == @source_collection_annotation
    target_collection.refs.should == @source_collection_refs
    target_collection.sort_field.should == @source_collection_sort
  end

  it 'should NOT copy attribution and references if user only owns target' do
    CollectionJob.new(command: 'copy', user: @has_target_but_not_source, collection: @source, collections: [@target],
                      collection_item_ids: [@source_collection.id]).run
    target_collection = @target.select_item(@collection)
    target_collection.annotation.should_not == @source_collection_annotation
    target_collection.refs.should_not == @source_collection_refs
    target_collection.sort_field.should_not == @source_collection_sort
  end

  it 'should move attibutions and references' do
    CollectionJob.new(command: 'move', user: @user, collection: @source, collections: [@target],
                      collection_item_ids: [@source_collection.id]).run
    target_collection = @target.select_item(@collection)
    target_collection.annotation.should == @source_collection_annotation
    target_collection.refs.should == @source_collection_refs
    target_collection.sort_field.should == @source_collection_sort
  end

  it 'should remove moved items if overwrite forced' do
    CollectionJob.new(command: 'move', user: @user, collection: @source, collections: [@target],
                      collection_item_ids: [@source_tc.id], overwrite: true).run
    collection_should_not_include(@source, @tc)
  end

  it 'should replace attributions and references on duplicates if copy overwrite forced' do
    CollectionJob.new(command: 'copy', user: @user, collection: @source, collections: [@target],
                      collection_item_ids: [@source_tc.id], overwrite: true).run
    target_tc = @target.select_item(@tc)
    target_tc.annotation.should == @source_tc_annotation
    target_tc.refs.should == @source_tc_refs
    target_tc.sort_field.should == @source_tc_sort
  end

  it 'should replace attributions and references on duplicates if move overwrite forced' do
    CollectionJob.new(command: 'move', user: @user, collection: @source, collections: [@target],
                      collection_item_ids: [@source_tc.id], overwrite: true).run
    target_tc = @target.select_item(@tc).reload
    target_tc.annotation.should == @source_tc_annotation
    target_tc.refs.should == @source_tc_refs
    target_tc.sort_field.should == @source_tc_sort
  end

  it 'should be invalid if copying without a target' do
    CollectionJob.new(command: 'copy', user: @user, collection: @source, collections: [], all_items: true).should_not be_valid
  end

  it 'should be invalid if moving without a target' do
    CollectionJob.new(command: 'move', user: @user, collection: @source, collections: [], all_items: true).should_not be_valid
  end

  it 'should be invalid if attempting to remove from an unowned source' do
    job = CollectionJob.new(command: 'remove', user: @has_target_but_not_source, collection: @source, all_items: true)
    job.should_not be_valid
  end

  it 'should be invalid if attempting to move from an unowned source' do
    CollectionJob.new(command: 'move', user: @has_target_but_not_source, collection: @source, collections: [@target], all_items: true).should_not be_valid
  end

  it 'should be invalid if attempting to move to an unowned target' do
    job = CollectionJob.new(command: 'move', user: @has_source_but_not_target, collection: @source, collections: [@target], all_items: true)
    job.should_not be_valid
  end

  it 'should be invalid if attempting to copy to an unowned target' do
    CollectionJob.new(command: 'copy', user: @has_source_but_not_target, collection: @source, collections: [@target], all_items: true).should_not be_valid
  end

  it 'should be invalid if attempting anything with no items and not all_items' do
    CollectionJob::VALID_COMMANDS.each do |command|
      CollectionJob.new(command: command, user: @user, collection: @source, collections: [@target]).should_not be_valid
    end
  end

  it 'should recalculate the relevance for the target after a copy' do
    @source.should_not_receive(:set_relevance)
    @target.should_receive(:set_relevance).and_return(49)
    all_item_job('copy').run
  end

  it 'should recalculate the relevances after a move' do
    @source.should_receive(:set_relevance).and_return(52)
    @target.should_receive(:set_relevance).and_return(48)
    all_item_job('move').run
  end

  it 'should recalculate the relevance after a remove' do
    @source.should_receive(:set_relevance).and_return(53)
    all_item_job('remove').run
  end

  it 'should reindex solr after a copy all' do
    EOL::Solr::CollectionItemsCoreRebuilder.should_receive(:reindex_collection).with(@target).and_return(true)
    all_item_job('copy').run
  end

  it 'should reindex solr after a move all' do
    EOL::Solr::CollectionItemsCoreRebuilder.should_receive(:reindex_collection).with(@source).and_return(true)
    EOL::Solr::CollectionItemsCoreRebuilder.should_receive(:reindex_collection).with(@target).and_return(true)
    all_item_job('move').run
  end

  it 'should reindex solr after a remove all' do
    EOL::Solr::CollectionItemsCoreRebuilder.should_receive(:remove_collection).with(@source).and_return(true)
    all_item_job('remove').run
  end

  it 'should reindex solr after a copy items' do
    EOL::Solr::CollectionItemsCoreRebuilder.should_receive(:reindex_collection_items).once.and_return(true) # Sadly, we can't tell what args will be passed in here...
    CollectionJob.new(command: 'copy', user: @user, collection: @source, collections: [@target], collection_item_ids: [@source_collection.id]).run
  end

  it 'should reindex solr after a move items' do
    EOL::Solr::CollectionItemsCoreRebuilder.should_receive(:reindex_collection_items).with([@source_collection]).and_return(true)
    CollectionJob.new(command: 'move', user: @user, collection: @source, collections: [@target], collection_item_ids: [@source_collection.id]).run
  end

  it 'should reindex solr after a remove items' do
    EOL::Solr::CollectionItemsCoreRebuilder.should_receive(:remove_collection_items).with([@source_collection]).and_return(true)
    CollectionJob.new(command: 'remove', user: @user, collection: @source, collections: [@target], collection_item_ids: [@source_collection.id]).run
  end

  it 'should be able to copy to multiple target collections'
  it 'should be able to move to multiple target collections'

end
