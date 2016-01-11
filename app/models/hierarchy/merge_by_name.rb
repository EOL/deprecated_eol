class Hierarchy
  class MergeByName
    # Hierarchy::MergeByName.merge_hierarchy(hierarchy)
    def self.merge_hierarchy(hierarchy)
      self.new(hierarchy).merge_hierarchy
    end

    def initialize(hierarchy)
      @hierarchy = hierarchy
      # There are better ways to do this, but this is clear enough, so:
      @entry_attributes = [:id, :name_id, :rank_id, :parent_id,
        :taxon_concept_id]
    end

    def merge_hierarchy
      @hierarchy.entries.roots.each { |root| merge_tree(root) }
    end

    # TODO: not sure if I want to walk down by depth, or (as here), down the
    # graph. Need to feel it out...
    def merge_tree(root)
      # We reset the hash of merges for each new tree, but make it an instance
      # variable so we don't have to pass it around.
      @matches = {}
      # Same: we want to know ancestry as we walk down the tree, so we can check
      # for previous merges.
      @ancestry = {}
      descendants = @hierarchy.entries.active.
        select(@entry_attributes).
        includes(name: { canonical_form: :name },
          synonyms: { name: { canonical_form: :name } }).
        where(["lft BETWEEN ? AND ?", root.lft, root.rgt]).
        order(:lft)
      # TODO: Hmmmn... tricky: we want to stop when we've found a virus.
      descendants.find_each do |entry|
        find_matches(entry)
      end
    end

    def find_matches(entry)
      remember_ancestors(entry)
      remember_matches(entry)
      match(entry, entry.name)
      match(entry, entry.name.canonical_form.name)
      entry.synonyms.each do |synonym|
        match(entry, synonym.name)
        match(entry, synonym.name.canonical_form.name)
      end
    end

    def remember_ancestors(entry)
      @ancestry[entry.id] = if @ancestry.has_key?(entry.parent_id)
        @ancestry[entry.parent_id] << entry.parent_id
      else
        [entry.parent_id]
      end
    end

    def remember_matches(entry)
      @matches[entry.id] = entry.taxon_concept.entry_ids
    end

    def match(this, name)
      return if name.nil?
      ancestors = @ancestry[this.id]
      matches = name.entries.active.select(@entry_attributes).
        includes(:taxon_concept)
      matches.each do |other|
      end
      # We want to see if we've matched any of its ancestors, first... because
      # if we have, it "scores" better for merging. We need to check the taxon
      # concept of each; if there are matches in any other single hierarchy, we
      # cannot merge them (because that hierarchy has told us that these are two
      # seprate things)... aaaaaannnd.... I think that's it? If it's a match, we
      # put OUR entry into THEIR concept (no need to do the whole lower-id
      # thing, I think).
    end
  end
end
