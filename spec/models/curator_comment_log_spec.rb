require File.dirname(__FILE__) + '/../spec_helper'

describe CuratorCommentLog do

  fixtures :roles

  it '#create_valid should be valid' do
    lambda { CuratorCommentLog.create_valid.should be_valid }.should change(CuratorCommentLog, :count).by(1)
  end

  it 'should create a log entry when a Comment is vetted by a curator' do
    bob   = User.create_valid!
    concept = HierarchyEntry.find(16222828).taxon_concept # cafeteria, it's under Chromista (16101659)
    comment = concept.comment bob, 'This concept is neato'
    comment.hide!
    comment.vetted?.should be_false
    bob.approve_to_curate! 16222828

    lambda { bob.vet comment }.should change(CuratorCommentLog, :count).by(1)
    log = CuratorCommentLog.last
    log.user.should == bob
    log.comment.should == comment
    log.activity.should == CuratorActivity.approve # vet => approval
  end

  it 'should create a log entry when a Comment is unvetted by a curator' do
    bob   = User.create_valid!
    concept = HierarchyEntry.find(16222828).taxon_concept # cafeteria, it's under Chromista (16101659)
    comment = concept.comment bob, 'This concept is neato'
    comment.show!
    comment.vetted?.should be_true
    bob.approve_to_curate! 16222828

    lambda { bob.unvet comment }.should change(CuratorCommentLog, :count).by(1)
    log = CuratorCommentLog.last
    log.user.should == bob
    log.comment.should == comment
    log.activity.should == CuratorActivity.disapprove # unvet => disapprove
  end

  it 'should mine correctly into daily summary statistics'

end
