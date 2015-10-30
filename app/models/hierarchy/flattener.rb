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
      rescue EmptyHierarchyFlattened => e
        EOL.log("WARNING: Hiearrchy #{@hierarchy.id} is empty!", prefix: "!")
        return nil
      end
      build_ancestry
      build_flat_entries_and_concepts
      update_tables
    end

    private

    def study_hierarchy
      EOL.log_call
      @children = {}
      @taxa = {}
      HierarchyEntry.published.visible_or_preview.not_untrusted.
        select("id, parent_id, taxon_concept_id").
        where(hierarchy_id: @hierarchy.id).find_each do |entry|
        @children[entry.parent_id] ||= Set.new
        @children[entry.parent_id] << entry.id
        @taxa[entry.id] = entry.taxon_concept_id
      end
      raise EOL::Exceptions::EmptyHierarchyFlattened.new if @children.empty?
    end

    def build_ancestry
      EOL.log_call
      @ancestry = {}
      @children[0].each do |root|
        walk_down_tree(root, [])
      end
    end

    def walk_down_tree(id, ancestors)
      return unless @children.has_key?(id)
      ancestors << id
      @children[id].each do |child_id|
        # NOTE: doesn't work without #reverse ... not sure why (?), but that's
        # fine, this is actually more accurate ... we just never _need_ to know
        # the order. ;)
        @ancestry[child_id] = ancestors.reverse
        walk_down_tree(child_id, ancestors)
      end
    end

    def build_flat_entries_and_concepts
      EOL.log_call
      @flat_entries = Set.new
      @flat_concepts = Set.new
      @ancestry.keys.each do |child|
        @ancestry[child].each do |ancestor|
          @flat_entries << "#{child},#{ancestor}"
          @flat_concepts << "#{@taxa[child]},#{@taxa[ancestor]}"
        end
      end
    end

    def update_tables
      debugger
      EOL.log_call
      HierarchyEntriesFlattened.delete_hierarchy_id(@hierarchy.id)
      EOL::Db.bulk_insert(HierarchyEntriesFlattened,
        [ "hierarchy_entry_id", "ancestor_id" ], @flat_entries)
      EOL::Db.bulk_insert(TaxonConceptsFlattened,
        [ "taxon_concept_id", "ancestor_id" ], @flat_concepts, ignore: true)
    end
  end
end
