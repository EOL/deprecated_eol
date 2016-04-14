# NOTE: I'm using instance variables to stop MALLOC'ing every time we call
# #compare, which is... a lot.
class Hierarchy::Similarity
  kingdom_friendly_ids = []
  [:kingdom, :phylum, :class_rank, :order].each do |rank_name|
    kingdom_friendly_ids += Rank.where(rank_group_id:
      Rank.send(rank_name).rank_group_id).pluck(:id)
  end
  kingdom_friendly_index = {}
  kingdom_friendly_ids.each { |id| kingdom_friendly_index[id] = true }
  RANKS_ALLOWED_TO_MATCH_AT_KINGDOM_ONLY = kingdom_friendly_index
  # NOTE: Genus is low because, presumedly, a binomial will always match at
  # the Genus if it's matched the name. :\
  RANK_WEIGHTS = { "genus" => 0.5, "family" => 0.9, "order" => 0.8,
    "class" => 0.6, "phylum" => 0.4, "kingdom" => 0.2 }
  # I am not going to freak out about the fact that TODO: this needs to be in
  # the database. I've lost my energy to freak out about such things. :|
  GOOD_SYNONYMY_HIERARCHY_IDS = [
    123, # WORMS
    143, # Fishbase
    622, # IUCN
    636, # Tropicos
    759, # NCBI
    787, # ReptileDB
    860, # Avibase
    903, # ITIS
    949  # COL 2012
  ]

  def initialize
    @solr ||= SolrCore::HierarchyEntries.new
    @studied = {}
    @rank_conflicts = {}
    @rank_groups = Hash[ *(Rank.where("rank_group_id != 0").
      flat_map { |r| [ r.id, r.rank_group_id ] }) ]
  end

  def compare(from_entry, to_entry, options = {})
    @from_entry = options[:from_studied] ? from_entry : study(from_entry)
    @to_entry = study(to_entry)
    return :same_entry if @from_entry["id"] == @to_entry["id"]
    return :from_name_blank if @from_entry["name"].blank?
    return :to_name_blank if @to_entry["name"].blank?
    return :same_hierarchy if options[:complete] &&
      @from_entry["hierarchy_id"] == @to_entry["hierarchy_id"]
    return :rank_ids_conflict if
      rank_ids_conflict?(@from_entry["rank_id"], @to_entry["rank_id"])
    # PHP: "viruses are a pain and will not match properly right now"
    return :virus if @from_entry["is_virus"] || @to_entry["is_virus"]
    clear_variables
    compare_names
    if @name_match == :none
      # 0 (none), 0.5 (canon), or 1 (sci):
      @synonym_match = compare_synonyms
      @is_synonym = @synonym_match != :none
    end
    score = if @name_match == :none && @synonym_match == :none
      0
    else
      compare_ancestries
      if @ancestry_score.nil?
        # One of the ancestries was totally empty:
        name_score * 0.5
      elsif @ancestry_score > 0
        # Ancestry was reasonable match:
        name_score * @ancestry_score
      else
        # Bad match:
        0
      end
    end
    { score: score, synonym: @is_synonym, name_match: @name_match,
      synonym_match: @synonym_match, from: @from_entry.id, to: @to_entry.id,
      kingdoms_match: @kingdoms_match, bad_kingdom: @bad_kingdom,
      from_has_non_kingdom: @from_has_non_kingdom,
      to_has_non_kingdom: @to_has_non_kingdom,
      non_kingdoms_match: @non_kingdoms_match,
      ancestry_empty: @ancestry_empty, ancestry_score: @ancestry_score,
      both_ancestries_have_non_kingdoms: @both_ancestries_have_non_kingdoms
    }
  end

  def load_entry(entry)
    entry = entry.from_solr.first if entry.is_a?(HierarchyEntry)
    unless entry.is_a?(Hash)
      entry = @solr.connection.
        get("select", params: { q: "id:#{entry}" } )["response"]["docs"].first
    end
    entry
  end

  def study(entry)
    if entry.is_a?(Fixnum) || entry.is_a?(String) &&
       @studied.has_key?(entry.to_i)
      return @studied[entry.to_i]
    end
    entry = load_entry(entry) unless entry.is_a?(Hash)
    if @studied.has_key?(entry["id"])
      return @studied[entry["id"]]
    end
    # April 2016: we decided that missing a scientific name (which is due to
    # non-ansi characters in the name) was insufficient cause to ignore it
    # entirely; match instead on the canonical form, which is clean.
    if entry["name"].blank?
      entry["name"] = entry["canonical_form"]
    end
    entry["rank_id"] ||= 0
    entry["kingdom_down"] = entry["kingdom"].try(:downcase)
    entry["quoted_canonical"] = metaquote(entry["canonical_form"])
    entry["quoted_name"] = metaquote(entry["name"])
    entry["is_virus"] = virus?(entry)
    entry["synonymy"] = synonymy_of(entry)
    @studied[entry["id"]] = entry
    entry
  end

  def metaquote(string)
    return "" if string.nil?
    string.gsub(/\\/, "\\\\\\\\").gsub(/"/, "\\\"")
  end

  def virus?(entry)
    return true if entry["kingdom_down"] &&
      (entry["kingdom_down"] == "virus" || entry["kingdom_down"] == "viruses")
    return entry["quoted_canonical"].size >= 5 &&
      entry["quoted_canonical"][-5..-1] == "virus"
  end

  def rank_ids_conflict?(rid1, rid2)
    (low, high) = [rid1, rid2].sort
    key = "#{low}v#{high}"
    return @rank_conflicts[key] if @rank_conflicts.has_key?(key)
    @rank_conflicts[key] = if @rank_groups.has_key?(rid1) &&
                              @rank_groups.has_key?(rid2)
      @rank_groups[rid1] != @rank_groups[rid2]
    else
      rid1 && rid1 != 0 && rid2 && rid2 != 0 && rid1 != rid2
    end
  end

  def clear_variables
    @is_synonym = nil
    @synonym_match = nil
    @name_match = nil
    @kingdoms_match = nil
    @from_has_non_kingdom = nil
    @to_has_non_kingdom = nil
    @non_kingdoms_match = nil
    @ancestry_empty = true
    @ancestry_score = 0
    @bad_kingdom = nil
    @both_ancestries_have_non_kingdoms = nil
  end

  def compare_names
    @name_match = if @from_entry["name"] == @to_entry["name"]
       :scientific
    elsif @from_entry["canonical_form"] && @to_entry["canonical_form"] &&
          @from_entry["canonical_form"] == @to_entry["canonical_form"]
      :canonical
    else
      :none
    end
  end

  def compare_synonyms
    if @to_entry["synonymy"].include?(@from_entry["name"]) ||
      @from_entry["synonymy"].include?(@to_entry["name"])
      :scientific
    elsif @to_entry["synonymy"].include?(@from_entry["canonical_form"]) ||
      @from_entry["synonymy"].include?(@to_entry["canonical_form"])
      :canonical
    else
      :none
    end
  end

  # "check each rank in order of priority and return the respective weight on
  # match"
  def compare_ancestries
    @ancestry_score = nil
    study_ancestry
    return nil if @ancestry_empty
    # Never ever match bad kingdoms:
    return 0 if @bad_kingdom
    if @kingdoms_match
      if @non_kingdoms_match
        # We matched on Kingdom AND something else, which is great!
        return 1
      else
        # We *only* had kingdoms to work with... If neither entry has other
        # ranks at all, return the score based on kingdom only:
        return RANK_WEIGHTS["kingdom"] unless
          @both_ancestries_have_non_kingdoms
        # So here we've got at least one entry with other ranks *available*,
        # but they didn't match. This is only okay if both entries have a rank
        # that allows this:
        return 0 unless
          allowed_to_match_at_kingdom_only?
        # If we haven't returned, then we're looking at a pair of higher-level
        # entries that matched only at kingdom (which is fine)
      end
    end
    @ancestry_score = @ancestry_score
  end

  def study_ancestry
    RANK_WEIGHTS.sort_by { |k,v| - v }.each do |rank, weight|
      if @from_entry[rank] && @to_entry[rank]
        @ancestry_empty = false
        unless rank == "kingdom"
          @from_has_non_kingdom = true
          @to_has_non_kingdom = true
        end
        if @from_entry[rank] == @to_entry[rank] # MATCH!
          if rank == "kingdom"
            @kingdoms_match = true
          else
            @non_kingdoms_match = true
          end
          @ancestry_score = weight if weight > @ancestry_score
        else # CONTRADICTION!
          if rank == "kingdom"
            # If either of them is Animalia, absolutely DO NOT MATCH!
            if @from_entry[rank].downcase == "animalia" ||
               @to_entry[rank].downcase == "animalia"
              @bad_kingdom = true
              return # Nothing more worth doing!
            end
          end
        end
      elsif @from_entry[rank]
        @ancestry_empty = false
        @from_has_non_kingdom = true unless rank == "kingdom"
      elsif @to_entry[rank]
        @ancestry_empty = false
        @to_has_non_kingdom = true unless rank == "kingdom"
      end
    end
    @both_ancestries_have_non_kingdoms =
      @to_has_non_kingdom && @from_has_non_kingdom
  end

  def allowed_to_match_at_kingdom_only?
    RANKS_ALLOWED_TO_MATCH_AT_KINGDOM_ONLY[@from_entry["rank_id"]] &&
      RANKS_ALLOWED_TO_MATCH_AT_KINGDOM_ONLY[@to_entry["rank_id"]]
  end

  def synonymy_of(entry)
    if GOOD_SYNONYMY_HIERARCHY_IDS[entry["hierarchy_id"]] && entry["synonym"]
      entry["synonym"]
    else
      []
    end
  end
end
