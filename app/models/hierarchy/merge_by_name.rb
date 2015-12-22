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
      @merges = {}
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
      descendants.find_each do |entry| # TODO: probably not.
        remember_ancestors(entry)
        match(entry, entry.name)
        match(entry, entry.name.canonical_form.name)
        entry.synonyms.each do |synonym|
          match(entry, synonym.name)
          match(entry, synonym.name.canonical_form.name)
        end
      end
    end

    def remember_ancestors(entry)
      @ancestry[entry.id] = if @ancestry.has_key?(entry.parent_id)
        @ancestry[entry.parent_id] << entry.parent_id
      else
        [entry.parent_id]
      end
    end

    def match(entry, name)
      return if name.nil?
      matches = name.entries.active.select(@entry_attributes).
        includes(:taxon_concept)
      # TODO: something... so, we've got a list here of entries that we could
      # potentially merge with.

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
