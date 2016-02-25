require 'spec_helper'

describe HierarchyReindexing do

  before(:each) do
    @hierarchy= Hierarchy.gen
    @hierarchy_reindexing= HierarchyReindexing.create(hierarchy_id: @hierarchy.id)
  end

   it 'uses HierarchyReindexing queue notification queue' do
    expect(HierarchyReindexing.class_eval { @queue }).to eq('notifications')
  end

  it "repopulates the flattened ancestors" do 
    expect_any_instance_of(Hierarchy).to receive(:repopulate_flattened)
    HierarchyReindexing.perform({"id"=> @hierarchy_reindexing.id})
  end

  it "raises error when the id is missing" do
     Rails.logger.should_receive(:error).twice.with(/HierarchyReindexing/)
     HierarchyReindexing.perform({"id"=> nil})

  end
  
  it "repopulates the flattened ancestors" do 
    expect_any_instance_of(Hierarchy).to receive(:repopulate_flattened)
    HierarchyReindexing.perform({"id"=> @hierarchy_reindexing.id})
  end
end
