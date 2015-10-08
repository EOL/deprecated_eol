module SolrCore
  class HierarchyEntries < SolrCore::Base
    CORE_NAME = "hierarchy_entries"

    def initialize
      connect(CORE_NAME)
    end

    # TODO: PUT THE GORRAM CANONICAL FORM IN THE HE TABLE!!! GRRR!
    def reindex_hierarchy(hierarchy)
      # TODO: Don't call the delete until you're good and ready!
      connection.delete_by_query("hierarchy_id:#{hierarchy.id}")
      objects = lookup_with_names
      lookup_ancestries
    end

    def lookup_with_names
      objects = []
      HierarchyEntry.
        select("hierarchy_entries.*, n.string, "\
          "rcf.string canonical_form_string").
        joins("LEFT JOIN (names n LEFT JOIN canonical_forms rcf "\
          "ON (n.ranked_canonical_form_id = rcf.id)) "\
          "ON (hierarchy_entries.name_id = n.id)").
        where(hierarchy_id: hierarchy.id).find_in_batches do |entries|
        entries.each do |entry|
          if string = entry["canonical_form_string"]
            # TODO: whoa, whoa, whoa: we should NOT be doing this here. :| We
            # should be calling GN for this kind of thing. ...And it should
            # already be in the DB! Argh.
            if string =~ /^(.* sp)\.?( |$)/
              entry["canonical_form"] = $1
            else
              entry["canonical_form"] =
                string.gsub(/ (var|convar|subsp|ssp|cf|f|f\.sp|c|\*)\.?( |$)/,
                  "\\2")
            end
          end
          objects << entry
        end
        ancestors = lookup_ancestries(entries)
      end
    end

    def lookup_ancestries(children)
      node_metadata = []
      next_layer_of_ids = Set.new(children.map { |c| c[:parent_id] }.compact)
      while ! next_layer_of_ids.empty?
        this_layer = next_layer_of_ids.dup
        next_layer_of_ids = Set.new
        HierarchyEntry.
          select("hierarchy_entries.id, hierarchy_entries.parent_id, "\
            "hierarchy_entries.rank_id, n.string, cf.string canonical_form").
          joins("LEFT JOIN (names n LEFT JOIN canonical_forms cf ON "\
            "(n.canonical_form_id = cf.id)) ON "\
            "(hierarchy_entries.name_id = n.id)").
          where(["hierarchy_entries.id IN (?)", this_layer])
          find_each do |entry|
          string = entry["canonical_form"] || entry["string"]
          node_metadata << entry
          next_layer_of_ids << entry["parent_id"]
        end
        next_layer_of_ids.delete(nil)
      end
      node_metadata
    end
  end
end
