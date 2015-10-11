class Hierarchy
  class Relator
    def self.relate(hierarchy, options)
      relator = self.new(hierarchy, options)
      relator.relate
    end

    def initialize(hierarchy, options)
      @hierarchy = hierarchy
      @entry_ids = options[:entries]
      # All TODO ... something tells me these all belong in the DB. :)
      set_ranks_matched_at_kingdom
      set_rank_comparison_array
      set_hierarchy_ids_with_good_synonymies
    end

    def relate
      # YOU WERE HERE
    end
  end
end
