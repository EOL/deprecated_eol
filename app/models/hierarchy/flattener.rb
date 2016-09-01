class Hierarchy
  class Flattener
    attr_reader :ancestry

    def self.flatten_all
      Hierarchy.browsable.each { |h| flatten(h) }
      Hierarchy.nonbrowsable.each { |h| flatten(h) }
    end

    def self.flatten(hierarchy)
      flattener = self.new(hierarchy)
      flattener.flatten
    end

    def initialize(hierarchy)
      @hierarchy = hierarchy
    end

    def flatten
      EOL.log("Hierarchy::Flattener.flatten(#{@hierarchy.id}) "\
        "#{@hierarchy.label} (RID: #{@hierarchy.resource.try(:id)})", prefix: "#")
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
      HierarchyEntry.with_master do
        HierarchyEntry.where(hierarchy_id: @hierarchy.id).published.
          pluck("CONCAT(id, ',', parent_id, ',', taxon_concept_id) ids").
          each do |str|
          (entry,parent,taxon) = str.split(",")
          @children[parent] ||= Set.new
          @children[parent] << entry
          @taxa[entry] = taxon
        end
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
          @flat_entries << "#{@hierarchy.id},#{child},#{ancestor}"
          @flat_concepts << "#{@taxa[child]},#{@taxa[ancestor] || 0},#{@hierarchy.id},#{child}"
        end
      end
      # Without returning something simple, the return value is huge, slowing
      # things down.
      true
    end

    def update_tables
      EOL.log("delete old hierarchy ancestry...", prefix: ".")
      FlatEntry.where(hierarchy_id: @hierarchy.id).delete_all
      # Now ensure that no later process gets an empty set!
      begin
        EOL::Db.bulk_insert(FlatEntry,
          [ "hierarchy_id", "hierarchy_entry_id", "ancestor_id" ],
          @flat_entries)
        @hierarchy.clear_ancestry_set
      rescue ActiveRecord::RecordNotUnique => e
        raise "Did you run this with_master? tried to create a duplicate "\
          "ancestor. #{e.message.sub(/VALUES.*$/, "VALUES ...")}"
      end

      FlatTaxon.where(hierarchy_id: @hierarchy.id).delete_all
      EOL::Db.bulk_insert(FlatTaxa,
      [ "taxon_concept_id", "ancestor_id", "hierarchy_id", "hierarchy_entry_id" ],
        @flat_concepts, ignore: true)
    end
  end
end
