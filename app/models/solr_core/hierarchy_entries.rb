class SolrCore
  class HierarchyEntries < SolrCore::Base
    CORE_NAME = "hierarchy_entries"

    # TODO: Absolutely ABSURD that this is not in the rank table. We're using
    # "groups", without giving each group an appropriate label. We should do
    # that.
    @solr_rank_map = {
      'kingdom' =>  :kingdom,
      'regn.' => :kingdom,
      'phylum' => :phylum,
      'phyl.' => :phylum,
      'class' => :class,
      'cl.' => :class,
      'order' => :order,
      'ord.' => :order,
      'family' => :family,
      'fam.' => :family,
      'f.' => :family,
      'genus' => :genus,
      'gen.' => :genus,
      'species' => :species,
      'sp.' => :species
    }

    attr_reader :ancestors

    def self.rank_label(rank_id)
      unless @rank_labels
        @rank_labels = {}
        TranslatedRank.where(language_id: Language.english.id).each do |trank|
          @rank_labels[trank.rank_id] = @solr_rank_map[trank.label] if
            @solr_rank_map.has_key?(trank.label)
        end
      end
      @rank_labels[rank_id]
    end

    def self.reindex_hierarchy(hierarchy)
      solr = self.new
      solr.reindex_hierarchy(hierarchy)
    end

    # TODO: whoa, whoa, whoa: we should NOT be doing this here. :| We should be
    # calling GN for this kind of thing. ...And it should already be in the DB!
    # Argh.
    def self.clean_canonical_form(string)
      # TODO: do we _really_ want the "sp" here? I doubt it aids searches. :\
      if string =~ /^(.* sp)\.?\b/
        $1
      else
        string.gsub(/\s+(var|convar|subsp|ssp|cf|f|f\.sp|c|\*)\.?\b/, "")
      end
    end

    def initialize
      connect(CORE_NAME)
      @ancestors = {}
    end

    # TODO: PUT THE GORRAM CANONICAL FORM / STRING IN THE H.E. TABLE!!! GRRR!
    def reindex_hierarchy(hierarchy)
      # NOTE: This could be MILLIONS of entries! Be sure you have the memory:
      objects = lookup_with_names(hierarchy.id)
      # NOTE: we do not delete by ids, here, since we want to delete HEs that
      # might no longer be published! So we delete everything in the hierarchy:
      connection.delete_by_query("hierarchy_id:#{hierarchy.id}")
      reindex_items(objects)
    end

    # NOTE: This works in batches... which is actually somewhat inefficient,
    # because it needs to look up ancestors multiple times.
    def lookup_with_names(hierarchy_id)
      objects = []
      HierarchyEntry.
        select("hierarchy_entries.*, n.string, "\
          "rcf.string canonical_form_string").
        joins("LEFT JOIN (names n LEFT JOIN canonical_forms rcf "\
          "ON (n.ranked_canonical_form_id = rcf.id)) "\
          "ON (hierarchy_entries.name_id = n.id)").
        where(hierarchy_id: hierarchy_id).find_in_batches do |entries|
        entries.each do |entry|
          if string = entry["canonical_form_string"]
            # TODO: deprecated. Don't do this.
            entry["canonical_form"] =
              self.class.clean_canonical_form(string)
          end
        end
        lookup_ancestries(entries)
        lookup_synonyms(entries)
        objects += entries
      end
      objects
    end

    # TODO: why don't we use flattened ancestors here? :S
    def lookup_ancestries(children)
      EOL.log_call
      already_found = Set.new(@ancestors.keys)
      next_ancestors = {}
      children.each do |child|
        next if child["parent_id"] == 0
        next_ancestors[child.id] = child["parent_id"]
      end
      parents = Set.new(next_ancestors.values)
      while ! parents.blank?
        EOL.log("Getting next layer of ancestors "\
          "(#{parents.count} ids)")
        this_layer = parents.dup
        parents = Set.new
        HierarchyEntry.
          select("hierarchy_entries.id, hierarchy_entries.parent_id, "\
            "hierarchy_entries.rank_id, n.string, cf.string canonical_form").
          joins("LEFT JOIN (names n LEFT JOIN canonical_forms cf ON "\
            "(n.canonical_form_id = cf.id)) ON "\
            "(hierarchy_entries.name_id = n.id)").
          where([ "hierarchy_entries.id IN (?)", this_layer - already_found ]).
          find_each do |entry|
          # We will use the string field, though prefer canonical if it exists:
          string = entry["canonical_form"] unless entry["canonical_form"].blank?
          rank = self.class.rank_label(entry.rank_id)
          @ancestors[entry.id] = { rank: rank, string: string,
            next: entry["parent_id"] }
          parents << entry["parent_id"]
          already_found << entry.id
        end
        # Now add what we know to the children:
        children.each do |child|
          if ancestor = @ancestors[next_ancestors[child.id]]
            if ancestor[:rank]
              child.ancestor_names ||= {}
              child.ancestor_names.merge!(ancestor[:rank] => ancestor[:string])
            end
            next_ancestors[child.id] = ancestor[:next]
          end
        end
        # Don't go past root nodes.
        parents.delete(nil).delete(0)
      end
      @ancestors
    end

    def lookup_synonyms(entries)
      EOL.log_call
      Synonym.select("synonyms.*, n.string, rcf.string canonical_form").
        # Sigh. Honestly, I'm not sure this is more efficient than the Rails
        # Way, but I am porting it as-is. :|
        joins("JOIN (names n LEFT JOIN canonical_forms rcf "\
          "ON (n.ranked_canonical_form_id = rcf.id)) "\
          "ON (synonyms.name_id = n.id)").
        where(["hierarchy_entry_id IN (?)", entries.map(&:id)]).
        each do |synonym|
        relation_id = synonym.synonym_relation_id # this variable is not used here?
        entry =
          entries.find { |e| e.id == synonym.hierarchy_entry_id }
        if synonym.common_name?
          entry.common_names ||= []
          entry.common_names << synonym["string"]
        else
          entry.synonyms ||= []
          entry.synonyms << synonym["string"]
          if synonym["canonical_form"]
            entry.canonical_synonyms ||= []
            entry.canonical_synonyms << self.class.
              clean_canonical_form(synonym["canonical_form"])
          end
        end
      end
    end
  end
end
