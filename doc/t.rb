# This is a temp file used for notes. Ignore it entirely!

@solr = SolrCore::HierarchyEntryRelationships.new

def get_page(query, page)
  @solr.paginate(query, page: page, per_page: 1000)["response"]["docs"]
end

merges = {}
ids.each do |id|
  resource = Hierarchy.find(id).resource
  next unless resource && resource.title
  these_merges = Set.new
  query = "confidence:0 AND relationship:name AND hierarchy_id_1:#{id}"
  page = 0
  docs = []
  begin
    page += 1
    docs = get_page(query, page)
    all_entry_ids = Set.new(docs.map { |d| d["hierarchy_entry_id_1"] })
    all_entry_ids += docs.map { |d| d["hierarchy_entry_id_2"] }
    entries = HierarchyEntry.includes(name: { canonical_form: :name }).
      published.where(id: all_entry_ids.to_a)
    docs.each do |doc|
      id1 = doc["hierarchy_entry_id_1"]
      id2 = doc["hierarchy_entry_id_2"]
      entry1 = entries.find { |e| e.id == id1 }
      entry2 = entries.find { |e| e.id == id2 }
      if entry1 && entry2 && entry1.taxon_concept_id == entry2.taxon_concept_id
        name1 = entry1.name.try(:canonical_form).try(:name).try(:string) || "NONAME!"
        name2 = entry2.name.try(:canonical_form).try(:name).try(:string) || "NONAME!"
        these_merges << "[#{entry1.taxon_concept_id}](http://eol.org/pages/#{entry1.taxon_concept_id}/overview) -> #{name1} (#{id1}), #{name2} (#{id2})"
      end
    end
  end while docs.size > 0
  merges["[#{resource.title}](http://eol.org/content_partners/#{resource.content_partner_id}/resources/#{resource.id})"] = these_merges
end

File.open("/app/log/resource_merges.md", "w") do |file|
  merges.keys.each do |title|
    file.write("#{title}:\n")
    merges[title].each do |val|
      file.write("  #{val}\n")
    end
  end
end

# --

params = {page: 1, exact: true, id: "Cistanthe weberbaueri (Diels) Carolin ex M.A.Hershkovitz"}
params[:q] = params[:id]

params = {page: 1, exact: true, id: "carnivores"}
params[:q] = params[:id]

params = {page: 1, exact: false, id: "tiger", filter_by_string: "Lepidoptera" }
params[:q] = params[:id]

params = {page: 1, exact: false, id: "chromatica", filter_by_string: "Lepidoptera" }
params[:q] = params[:id]

params = {page: 1, exact: false, id: "chromatica", filter_by_taxon_concept_id: 747 }
params[:q] = params[:id]


# --

resource = Resource.find(544)
event = resource.harvest_events.last
@solr = SolrCore::SiteSearch.new
@solr.index_type(TaxonConcept, HierarchyEntry.where(id: event.new_hierarchy_entry_ids).pluck(:taxon_concept_id))


# Delete me later!

@resource = Resource.find 974 # North American Butterflies and Skippers

concept1 = TaxonConcept.find 45882481
concept2 = TaxonConcept.find 250906

entry1 = HierarchyEntry.find 63226353
entry2 = HierarchyEntry.find 55715950

@solr = SolrCore::HierarchyEntryRelationships.new
@hierarchy = Hierarchy.find 1505
@compared = []
@all_hierarchies = false
@confirmed_exclusions = {}
@entries_matched = []
@supercedures = {} # The ones we do
@superceded = {} # ALL superceded ids we encounter, ever (saves queries)
@visible_id = Visibility.get_visible.id
@preview_id = Visibility.get_preview.id
@per_page = 10
page = 1

hierarchy1 = @hierarchy
hierarchy2 = Hierarhcy.find 903

matches_in_h1 = @solr.paginate("hierarchy_id_1:#{hierarchy1.id} AND (visibility_id_1:#{@visible_id} OR visibility_id_1:#{@preview_id}) AND same_concept:false AND (relationship:name OR confidence:[0.25 TO *])", per_page: 2)["response"]["numFound"]

full_q = "hierarchy_id_1:#{hierarchy1.id} AND (visibility_id_1:#{@visible_id} OR visibility_id_1:#{@preview_id}) AND hierarchy_id_2:#{hierarchy2.id} AND (visibility_id_2:#{@visible_id} OR visibility_id_2:#{@preview_id}) AND same_concept:false"
options = { sort: "relationship asc, visibility_id_1 asc, visibility_id_2 asc, confidence desc, hierarchy_entry_id_1 asc, hierarchy_entry_id_2 asc"}.merge(page: page, per_page: @per_page)
response = @solr.paginate(full_q, options)
entries = response["response"]["docs"]

# - Moving backward to Relator...

@solr = SolrCore::HierarchyEntries.new
response = @solr.paginate("hierarchy_id:#{@hierarchy.id}", page: page, per_page: @per_page)
entries = response["response"]["docs"]
entries_in_solr = @solr.paginate("hierarchy_id:#{@hierarchy.id}", page: page, per_page: 1)["response"]["numFound"]

from_entry = @solr.paginate("id:#{entry1.id}", page: page, per_page: 1)["response"]["docs"][0]
to_entry = @solr.paginate("id:#{entry2.id}", page: page, per_page: 1)["response"]["docs"][0]


# When ready:
@resource = Resource.find 974
@resource.preview
