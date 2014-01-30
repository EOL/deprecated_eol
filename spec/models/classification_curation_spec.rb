require "spec_helper"

describe ClassificationCuration do


  before(:all) do
    load_foundation_cache
    @user = User.gen
    @exemplar = HierarchyEntry.gen
    @source = TaxonConcept.gen
    @target = TaxonConcept.gen
    @merged_source = TaxonConcept.gen
    @hierarchy_entries = [HierarchyEntry.gen, HierarchyEntry.gen, HierarchyEntry.gen]
    @split_args = { user_id: @user.id, source_id: @source.id, exemplar_id: @exemplar.id,
                    hierarchy_entries: @hierarchy_entries }
    @merge_args = { user_id: @user.id, source_id: @source.id, target_id: @target.id }
    @move_args  = { user_id: @user.id, source_id: @source.id, target_id: @target.id, exemplar_id: @exemplar.id,
                    hierarchy_entries: @hierarchy_entries }
  end

  let(:pre_split) { ClassificationCuration.new(@split_args) }
  let(:pre_merge) { ClassificationCuration.new(@merge_args) }
  let(:pre_move)  { ClassificationCuration.new(@move_args) }
  let(:split)     { ClassificationCuration.create(@split_args) }
  let(:php_split) { ClassificationCuration.create(@split_args) }

  before(:each) do
    # Disable interfaces to other classes: we don't want any funny business...
    CodeBridge.stub(:split_entry)
    CodeBridge.stub(:merge_taxa)
    CodeBridge.stub(:move_entry)
    Resque.stub(:enqueue)
    php_split.hierarchy_entry_moves.each { |move| move.update_attributes(completed_at: Time.now) }
  end

  it 'should call bridge after creation' do
    pre_split.should_receive(:bridge).and_return(nil)
    pre_split.save
  end

  it 'should know when it is a split' do
    pre_split.split?.should be_true
  end

  it 'should know when it is a move' do
    pre_move.move?.should be_true
  end

  it 'should know when it is a merge' do
    pre_merge.merge?.should be_true
  end

  it '#split should split all hierarchy entries from source taxon concept through CodeBridge' do
    # Typically, you call ClassificationCuration by passing in an array of hierarchy_entries. We fake that:
    pre_split.stub(:hierarchy_entries).and_return(@hierarchy_entries)
    CodeBridge.should_receive(:split_entry).exactly(@hierarchy_entries.length).times.and_return(nil)
    CodeBridge.should_not_receive(:merge_taxa)
    CodeBridge.should_not_receive(:move_entry)
    pre_split.save
  end

  it '#merge should merge both taxa (source and target) through CodeBridge' do
    # Typically, you call ClassificationCuration by passing in an array of hierarchy_entries. We fake that:
    pre_merge.stub(:hierarchy_entries).and_return(@hierarchy_entries)
    CodeBridge.should_not_receive(:split_entry)
    CodeBridge.should_receive(:merge_taxa).once.and_return(nil)
    CodeBridge.should_not_receive(:move_entry)
    pre_merge.save
  end

  it '#move should move all hierarchy entries from source taxon concept through CodeBridge' do
    # Typically, you call ClassificationCuration by passing in an array of hierarchy_entries. We fake that:
    pre_move.stub(:hierarchy_entries).and_return(@hierarchy_entries)
    CodeBridge.should_not_receive(:split_entry)
    CodeBridge.should_not_receive(:merge_taxa)
    CodeBridge.should_receive(:move_entry).exactly(@hierarchy_entries.length).times.and_return(nil)
    pre_move.save
  end

  it '#check_status_and_notify should reindex taxa and log completion' do
    php_split.should_receive(:reindex_taxa).and_return(nil)
    php_split.should_receive(:log_completion).and_return(nil)
    php_split.check_status_and_notify
  end

  it '#check_status_and_notify should NOT reindex taxa and log completion if not ready' do
    split.should_not_receive(:reindex_taxa)
    split.should_not_receive(:log_completion)
    split.check_status_and_notify
  end

  it '#check_status_and_notify should reindex taxa and log completion ONCE' do
    php_split.check_status_and_notify
    php_split.should_not_receive(:reindex_taxa)
    php_split.should_not_receive(:log_completion)
    php_split.check_status_and_notify
  end

  it '#check_status_and_notify should log errors if there were any' do
    php_split.hierarchy_entry_moves.second.update_attributes(error: "Something horrible")
    php_split.check_status_and_notify
    @source.comments.select {|c| c.body =~ /Something horrible/}.should_not be_empty
  end

  it 'should know where a split ended up' do
    move = double(HierarchyEntryMove)
    split.should_receive(:hierarchy_entry_moves).and_return([move])
    entry = double(HierarchyEntry)
    move.should_receive(:hierarchy_entry).and_return(entry)
    entry.should_receive(:taxon_concept).and_return(:this)
    split.split_to.should == :this
  end

  # TODO - I lost momentum, here. Thoughts:
  # I'm testing that reindex_taxa is being called, when I suppose it's more useful to test that
  # TaxonConceptReindexing is being called (correctly). That's probably worth extracting, though, into a method.
  # ...same thing with log_completion. Those should test the CuratorActivityLog and PendingNotification calls.
  # I haven't tested some public-facing methods that are worth it: 
  # already_complete?
  # ready_to_complete?
  # failed?
  # reindex_taxa and log_completion should also be tested.  Or moved to a single method; I really don't want to call
  # them separately, so they could be made private and a single method could call both.

end

