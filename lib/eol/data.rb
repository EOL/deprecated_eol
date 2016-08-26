module EOL

  module Data

    # for each Hierarchy, make the nested sets for that Hierarchy via .make_nested_set
    def self.make_all_nested_sets
      Hierarchy.find(:all).each do |hierarchy|
        EOL::Data.make_nested_set hierarchy
      end
    end

    # grabs the top-level HierarchyEntry nodes of a given Hierarchy and assigns proper
    # lft/rgt IDs to them and their children via .assign_id
    def self.make_nested_set hierarchy
      next_range_id = 1
      hierarchy.hierarchy_entries.select {|entry| entry.parent_id == 0 }.each do |entry|
        next_range_id = EOL::Data.assign_id entry, next_range_id
      end
    end

    # recurses through the childred of a HierarchyEntry and, given the current 'next_range_id',
    # assigns their lft/rgt IDs properly via .assign_id
    def self.make_nested_set_recursion entry, next_range_id
      entry.children.each do |child|
        next_range_id = EOL::Data.assign_id child, next_range_id
      end
      return next_range_id
    end

    # assigns the proper lft/right IDs to a HierarchyEntry given the current 'next_range_id'
    # and calls .make_nested_set_recursion to assign_id for the entry's children
    def self.assign_id entry, next_range_id
      entry.lft = next_range_id
      next_range_id += 1
      next_range_id = EOL::Data.make_nested_set_recursion entry, next_range_id
      entry.rgt = next_range_id
      next_range_id += 1
      entry.save!
      return next_range_id
    end

    # for each Hierarchy, make the nested sets for that Hierarchy via .make_nested_set
    def self.flatten_hierarchies
      root_he = HierarchyEntry.new
      root_he.id = 0
      Hierarchy.find(:all).each do |hierarchy|
        Hierarchy.flatten
      end
    end

    def self.rebuild_collection_type_nested_set
      CollectionType.find(:all).each do |ct|
        ct.lft = ct.rgt = 0
        ct.save!
      end
      nested_set_value = 0
      CollectionType.find_all_by_parent_id(0).each do |ct|
        nested_set_value = EOL::Data.rebuild_collection_type_nested_set_assign(ct, nested_set_value)
      end
    end

    def self.rebuild_collection_type_nested_set_assign(ct, nested_set_value)
      ct.lft = nested_set_value
      ct.save!
      nested_set_value += 1

      CollectionType.find_all_by_parent_id(ct.id).each do |child_ct|
        nested_set_value = EOL::Data.rebuild_collection_type_nested_set_assign(child_ct, nested_set_value)
      end

      ct.rgt = nested_set_value
      ct.save!
      nested_set_value += 1

      return nested_set_value
    end

  end

end
