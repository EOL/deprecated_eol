require File.dirname(__FILE__) + '/../spec_helper'

describe CuratorDataObjectLog do

  fixtures :roles

  it '#create_valid should be valid' do
    lambda { CuratorDataObjectLog.create_valid.should be_valid }.should change(CuratorDataObjectLog, :count).by(1)
  end

  it 'should create a log entry when a DataObject is vetted by a curator' do
    bob   = User.create_valid!
    object = create_dataobject_in_clade 16222828 # cafeteria, it's under Chromista (16101659)
    object.update_attribute :vetted_id, Vetted.unknown.id
    object.vetted?.should be_false
    bob.approve_to_curate! 16222828

    lambda { bob.vet object }.should change(CuratorDataObjectLog, :count).by(1)
    log = CuratorDataObjectLog.last
    log.user.should == bob
    log.object.should == object
    log.data_object.should == object
    log.activity.should == CuratorActivity.approve # vet => approval
  end

  it 'should create a log entry when a DataObject is unvetted by a curator' do
    bob   = User.create_valid!
    object = create_dataobject_in_clade 16222828 # cafeteria, it's under Chromista (16101659)
    object.update_attribute :vetted_id, Vetted.unknown.id
    object.vetted?.should be_false
    bob.approve_to_curate! 16222828

    lambda { bob.unvet object }.should change(CuratorDataObjectLog, :count).by(1)
    log = CuratorDataObjectLog.last
    log.user.should == bob
    log.object.should == object
    log.data_object.should == object
    log.activity.should == CuratorActivity.disapprove # unvet => disapprove
  end

  it 'should mine correctly into daily summary statistics'

end
