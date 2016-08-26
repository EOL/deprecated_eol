describe Hierarchy::Flattener do
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
    {
      entry_2_1 => [entry_2],
      entry_1_2 => [entry_1],
      entry_1_2_3 => [entry_1_2, entry_1]
    }.each do |child, ancestors|
      ancestors.each do |ancestor|
        expect(FlatEntry.exists?(hierarchy_entry_id: child.id,
          ancestor_id: ancestor.id)).to be_true
      end
    end
    [entry_1, entry_2, entry_3].each do |root|
      expect(FlatEntry.exists?(hierarchy_entry_id: root.id)).to_not be_true
    end
  end
end
