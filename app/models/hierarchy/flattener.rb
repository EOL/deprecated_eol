class Hierarchy
  class Flattener
    attr_reader :ancestry

    def self.flatten(hierarchy)
      flattener = self.new(hierarchy)
      flattener.flatten
    end

    def initialize(hierarchy)
      @hierarchy = hierarchy
    end

    # NOTE: we don't delete anything from TaxonConceptsFlattened, since that's
    # not really possible given only a single hierarchy (the same relationships
    # are likely to occur due to other hierarchies, so removing them would be
    # incorrect). Thus we'll have to rely on that table being maintained by
    # TaxonConcept.merge_ids, which _should_ be the only time that would be
    # affected. ...That's probably _not_ a safe assumption, though: hierarchy
    # entries that are unpublished _might_ also have an effect there. ...Would
    # be best if we rebuilt that table periodically, even though doing so would
    # be rather hairy! TODO
    def flatten
      EOL.log_call
      begin
        study_hierarchy
      rescue EOL::Exceptions::EmptyHierarchyFlattened => e
        EOL.log("WARNING: Hierarchy #{@hierarchy.id} is empty!", prefix: "!")
        return nil
      end
      build_ancestry
      build_flat_entries_and_concepts
      update_tables
    end

    private

    def study_hierarchy
      @children = {}
      @taxa = {}
      # I'm changing this... not sure it's for the better, but my thinking is
      # that it doesn't really matter if it's published or whatnot, since you're
      # always calling it by id... so you're checking published on that id: WAS:
      # HierarchyEntry.published.visible_or_preview.not_untrusted. This query
      # takes about 25 seconds on 500K entries, and the block takes a few
      # seconds more to process.
      HierarchyEntry.where(hierarchy_id: @hierarchy.id).
        pluck("CONCAT(id, ',', parent_id, ',', taxon_concept_id) ids").
        each do |str|
        (entry,parent,taxon) = str.split(",")
        @children[parent] ||= Set.new
        @children[parent] << entry
        @taxa[entry] = taxon
      end
      raise EOL::Exceptions::EmptyHierarchyFlattened.new if @children.empty?
    end

    def build_ancestry
      @ancestry = {}
      walk_down_tree("0", [])
    end

    def walk_down_tree(id, ancestors)
      return unless @children.has_key?(id)
      ancestors_here = ancestors.dup
      ancestors_here << id
      @children[id].each do |child_id|
        @ancestry[child_id] = ancestors_here
        walk_down_tree(child_id, ancestors_here)
      end
    end

    def build_flat_entries_and_concepts
      @flat_entries = Set.new
      @flat_concepts = Set.new
      @ancestry.keys.each do |child|
        @ancestry[child].each do |ancestor|
          @flat_entries << "#{child},#{ancestor}"
          @flat_concepts << "#{@taxa[child]},#{@taxa[ancestor] || 0}"
        end
      end
      # Without returning something simple, the return value is huge, slowing
      # things down.
      true
    end

    def update_tables
      currently = @hierarchy.ancestry_set
      EOL.log("Currently: #{currently.count}", prefix: ".")
      EOL.log("Desired: #{@flat_entries.count}", prefix: ".")
      old = currently - @flat_entries
      EOL.log("Old: #{old.count}", prefix: ".")
      create = @flat_entries - currently
      EOL.log("New: #{create.count}", prefix: ".")

      HierarchyEntriesFlattened.delete_set(old)
      EOL::Db.bulk_insert(HierarchyEntriesFlattened,
        [ "hierarchy_entry_id", "ancestor_id" ], create)

      EOL::Db.bulk_insert(TaxonConceptsFlattened,
        [ "taxon_concept_id", "ancestor_id" ], @flat_concepts, ignore: true)
    end
  end
end
