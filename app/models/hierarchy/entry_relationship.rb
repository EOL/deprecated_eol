class Hierarchy::EntryRelationship
  def initialize(entry1, entry2, other = {})
    @entry1 = entry1
    @entry2 = entry2
    @hierarchy1 = other[:hierarchy1] || entry1.hierarchy
    @hierarchy2 = other[:hierarchy1] || entry2.hierarchy
    @relationship = "name"
    @relationship = "syn" if other[:syn] || other[:relationship] == "syn"
    @same_concept = other[:same_concept] # Defaults to false.
    @confidence = other[:confidence] || 0.5 # Weird to have a default. :\
  end

  def query
    @solr = SolrCore::HierarchyEntryRelationships.new
    response = @solr.paginate(
      "hierarchy_entry_id_1:#{@entry1.id} AND "\
      "hierarchy_entry_id_2:#{@entry2.id}",
      Hierarchy::ConceptMerger.compare_hierarchies_options(1))
    response["response"]["docs"]
  end

  def to_hash
    { "hierarchy_entry_id_1" => @entry1.id,
      "taxon_concept_id_1" => @entry1.taxon_concept_id,
      "hierarchy_id_1" => @entry1.hierarchy_id,
      "visibility_id_1" => @entry1.visibility_id,
      "hierarchy_entry_id_2" => @entry2.id,
      "taxon_concept_id_2" => @entry2.taxon_concept_id,
      "hierarchy_id_2" => @entry2.hierarchy_id,
      "visibility_id_2" => @entry2.visibility_id,
      "same_concept" => !! @same_concept,
      "relationship" => @relationship,
      "confidence" => @confidence }
  end
end
