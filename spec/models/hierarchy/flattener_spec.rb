describe Hierarchy::Flattener do
<<<<<<< HEAD
  
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
=======

  before(:all) do
    populate_tables(:vetted, :visibilities)
  end

  let!(:hierarchy) { Hierarchy.gen }
  let!(:entry_1) { HierarchyEntry.gen(hierarchy_id: hierarchy.id) }
  let!(:entry_2) { HierarchyEntry.gen(hierarchy_id: hierarchy.id) }
  let!(:entry_3) { HierarchyEntry.gen(hierarchy_id: hierarchy.id) }
  let!(:entry_1_2) { HierarchyEntry.gen(hierarchy_id: hierarchy.id,
    parent_id: entry_1.id) }
  let!(:entry_1_2_3) { HierarchyEntry.gen(hierarchy_id: hierarchy.id,
    parent_id: entry_1_2.id) }
  let!(:entry_2_1) { HierarchyEntry.gen(hierarchy_id: hierarchy.id,
    parent_id: entry_2.id) }

  subject(:flattener) { Hierarchy::Flattener.new(hierarchy) }

  it 'should create ancestry' do
    expect(flattener.flatten).not_to raise_error
    flats = HierarchyEntriesFlattened.where(hierarchy_entry_id: entry_1_2_3.id)
    {
      entry_2_1 => [entry_2],
      entry_1_2 => [entry_1],
      entry_1_2_3 => [entry_1_2, entry_1]
    }.each do |child, ancestors|
      ancestors.each do |ancestor|
        puts "Flat? entry_id: #{child.id}, ancestor_id: #{ancestor.id}"
        expect(HierarchyEntriesFlattened.exists?(hierarchy_entry_id: child.id,
          ancestor_id: ancestor.id)).to be_true
      end
    end
    [entry_1, entry_2, entry_3].each do |root|
      expect(HierarchyEntriesFlattened.exists?(hierarchy_entry_id: root.id)).
        to_not be_true
    end
  end
end
>>>>>>> 0889efb55ee5a45c8244a4c4530fdf882d1b626c
