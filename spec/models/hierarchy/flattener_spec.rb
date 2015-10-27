describe Hierarchy::Flattener do
  
  before(:all) do
    truncate_all_tables
    Vetted.create_enumerated
    Visibility.create_enumerated
    @hierarchy = Hierarchy.gen
    @flattener = Hierarchy::Flattener.new(@hierarchy)
  end

  context 'no hierarchy entries' do
    it 'should raise empty hierarchy exception when hierarchy has no entries' do
      expect{@flattener.flatten}.to raise_error(RuntimeError, "Empty hierarchy")
    end
  end
  
  context 'unpublished or unvetted hierarchy entries' do
    before(:all) do
      5.times do
        @hierarchy.hierarchy_entries << HierarchyEntry.gen
      end
    end
    
    it 'should raise empty hierarchy exception when hierarchy has unpublished entries' do
      @hierarchy.hierarchy_entries.update_all(published: false)
      expect{@flattener.flatten}.to raise_error(RuntimeError, "Empty hierarchy")
    end
    
    it 'should raise empty hierarchy exception when hierarchy has invisible entries' do
      @hierarchy.hierarchy_entries.update_all(visibility_id: Visibility.get_invisible.id)
      expect{@flattener.flatten}.to raise_error(RuntimeError, "Empty hierarchy")
    end
    
    it 'should raise empty hierarchy exception when hierarchy has untrusted entries' do
      @hierarchy.hierarchy_entries.update_all(vetted_id: Vetted.untrusted.id)
      expect{@flattener.flatten}.to raise_error(RuntimeError, "Empty hierarchy")
    end
    
  end
  
  context 'hierarchy with visible vetted entries in skewed tree' do
    before(:all) do
      @hierarchy.hierarchy_entries = []
      @hierarchy.hierarchy_entries << HierarchyEntry.gen(parent_id: 0)
      99.times do
        @hierarchy.hierarchy_entries << HierarchyEntry.gen(parent_id: HierarchyEntry.find(:last).id)
      end
      @flattener.flatten
    end
    
    it 'should have children set' do
      expect(@flattener.instance_variable_get(:@children).size).to eq(100)
    end
    
    it 'should have taxa set' do
      expect(@flattener.instance_variable_get(:@taxa).size).to eq(100)
    end
    
    it 'should have one child only for each parent' do
      children = @flattener.instance_variable_get(:@children)
      children.each do |key, value|
        expect(value.size).to eq(1)
      end
    end
    
    it 'should have ancestory set' do
      expect(@flattener.instance_variable_get(:@ancestry).size).to eq(99)
    end
    
    it 'should have flat entries set and flat concepts set' do
      expect(@flattener.instance_variable_get(:@flat_entries).size).to be eq(100)
    end
    
    it 'should flat concepts set' do
      expect(@flattener.instance_variable_get(:@flat_concepts).size).to be > 0
    end
    
    it 'should have 99 ancestors for the leaf node' do
      expect(@flattener.instance_variable_get(:@ancestry).values.last.size).to eq(99)
    end
    
  end
  
  # context 'hierarchy with visible vetted entries in skewed tree' do
    # before(:all) do
      # @hierarchy.hierarchy_entries = []
      # @hierarchy.hierarchy_entries << HierarchyEntry.gen(parent_id: 0)
      # # tree levels
      # 5.times do
        # parent_id = @hierarchy.hierarchy_entries << HierarchyEntry.gen(parent_id: HierarchyEntry.find(:last).id)
        # # nodes per level
        # 3.times do
          # @hierarchy.hierarchy_entries << parent_id
        # end
      # end
      # @flattener.flatten
    # end
#     
    # it 'should have children set' do
      # expect(@flattener.instance_variable_get(:@children).size).to be > 0
    # end
#     
    # it 'should have taxa set' do
      # expect(@flattener.instance_variable_get(:@taxa).size).to be > 0
    # end
#     
    # it 'should have one child only for each parent' do
      # children = @flattener.instance_variable_get(:@children)
      # children.each do |key, value|
        # expect(value.size).to eq(1)
      # end
    # end
#     
    # it 'should have ancestory set' do
      # expect(@flattener.instance_variable_get(:@ancestry).size).to be > 0
    # end
#     
    # it 'should have flat entries set and flat concepts set' do
      # expect(@flattener.instance_variable_get(:@flat_entries).size).to be > 0
    # end
#     
    # it 'should flat concepts set' do
      # expect(@flattener.instance_variable_get(:@flat_concepts).size).to be > 0
    # end
#     
    # it 'should have 99 ancestors for the leaf node' do
      # expect(@flattener.instance_variable_get(:@ancestry).values.last.size).to eq(99)
    # end
#     
  # end
  
end