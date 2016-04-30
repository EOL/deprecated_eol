# This is a temp file used for notes. Ignore it entirely!

# https://github.com/EOL/tramea/issues/272

@user = User.find(20470)
# lines = IO.readlines("/app/log/AllBad_other.tsv") ; lines.size

# CSV.foreach("/app/log/AllBad_secser_sample.tsv", col_sep: "\t", encoding: 'windows-1251:utf-8') do |line|
pairs = {}
index = 0
CSV.foreach("/app/log/AllBad_other.tsv", col_sep: "\t") do |line|
  index += 1
  EOL.log("#{index}") if index % 10_000 == 0
  begin
    page = line[0]
    id1 = line[1]
    id2 = line[5]
    EOL.log("Line #{index} was missing a page id") && next if page.blank?
    EOL.log("Line #{index} was missing the first entry id") && next if id1.blank?
    EOL.log("Line #{index} was missing the second entry id") && next if id2.blank?
    pairs[page] = [id1, id2]
  rescue => e
    EOL.log("LINE #{index} BAD (#{e.message}): #{page}:#{id1}:#{id2}")
  end
end ; pairs.keys.size

entries = {}
group_num = 0
group_size = 1000
expected_groups = (pairs.keys.size.to_f / group_size).ceil
pairs.keys.in_groups_of(group_size, false) do |group|
  group_num += 1
  EOL.log("Working on group #{group_num}/#{expected_groups}...")
  ids = Set.new()
  group.each do |key|
    ids << pairs[key][0]
    ids << pairs[key][1]
  end
  HierarchyEntry.includes(name: { canonical_form: :name }).
                 where(id: ids.to_a).find_each do |entry|
    entries[entry.id] = entry
  end
end ; entries.keys.size

splits = {}
@lines = {}
concept_ids = Set.new()
pairs.each do |page, bad_entries|
  (id1, id2) = bad_entries
  page_id = page.to_i
  entry1 = entries[id1.to_i]
  entry2 = entries[id2.to_i]
  if entry1.nil?
    EOL.log("Missing entry #{id1}")
    next
  elsif entry2.nil?
    EOL.log("Missing entry #{id2}")
    next
  elsif entry1.taxon_concept_id != entry2.taxon_concept_id
    EOL.log("NOT THE SAME CONCEPT: #{page}:#{id1}:#{id2}")
    next
  elsif entry1.taxon_concept_id != page_id
    EOL.log("Concept changed: #{page}:#{id1}:#{id2} (to #{entry1.taxon_concept_id} from #{page})")
    next
  end
  concept_ids << page.to_i
  splits[page_id] ||= Set.new
  splits[page_id] << entry1
  splits[page_id] << entry2
  @lines[page_id] ||= Set.new
  @lines[page_id] << "#{page}:#{id1}:#{id2}"
end ; splits.keys.size

concepts = {}
TaxonConcept.where(id: concept_ids.to_a).find_each do |concept|
  concepts[concept.id] = concept
end ; concepts.keys.size

def problem(page_id)
  EOL.log("Affected lines:")
  @lines[page_id].each do |line|
    EOL.log("  #{line}")
  end
end

error_count = 0
splits.each do |page_id, bad_entries|
  unless concepts.has_key?(page_id)
    EOL.log("Missing concept #{page_id}... superceded, perhaps?")
    next
  end
  if concepts[page_id].superceded?
    EOL.log("Concept #{page_id} superceded, skipping.")
    next
  end
  if bad_entries.include?(nil)
    EOL.log("Skipping #{page_id} because one of the entries was nil.")
    error_count += 1
    # If more than 1% are bad, bail:
    if error_count > splits.keys.size / 100
      EOL.log("Whoa! Too many errors, bailing.")
      break
    end
    next
  end
  if bad_entries.any? { |e| e.name.nil? }
    EOL.log("Skipping #{page_id} because one of the entries had no name.")
    error_count += 1
    # If more than 1% are bad, bail:
    if error_count > splits.keys.size / 100
      EOL.log("Whoa! Too many errors, bailing.")
      break
    end
    next
  end
  sorted = bad_entries.sort_by { |e| e.name.try(:canonical_form).try(:string) }
  name1 = sorted.first.name.try(:canonical_form).try(:string)
  exemplar_id = sorted.first.id
  index = sorted.index { |e| e.name.try(:canonical_form).try(:string).length > name1.length }
  if index.nil?
    EOL.log("ERROR: Couldn't find a longer name")
    problem(page_id)
    next
  end
  other_ids = sorted[index..-1].map(&:id)
  begin
    concepts[page_id].split_classifications(other_ids, user: @user, exemplar_id: exemplar_id)
  rescue EOL::Exceptions::ClassificationsLocked => e
    EOL.log("ERROR: LOCKED CLASSIFICATION (TC ##{concept.id}):")
    problem(concept)
    next
  rescue EOL::Exceptions::TooManyDescendantsToCurate => e
    EOL.log("ERROR: TOO BIG: #{line}")
    problem(concept)
    next
  rescue => e
    EOL.log("ERROR: MISC... #{line}")
    EOL.log_error(e)
    problem(concept)
    next
  end
  sleep(1)
end

# Fixing broken hierarchies:

> log/reflatten.log
nohup bundle exec rails runner -e production "
Resource.with_master {
  Resource.harvested.includes(:hierarchy).each { |r|
    EOL.log(%Q{#{r.title} (#{r.id})}) ;
    h = r.hierarchy ;
    EOL.log(%Q{Empty hierarchy!}) unless h ;
    next unless h ;
    e = h.hierarchy_entries.where(depth: 4).first ;
    EOL.log(%Q{Nothing deep enough to check!}) unless e ;
    EOL.log(%Q{Already OK.}) if e and e.ancestors.size == 4 ;
    next if e and e.ancestors.size == 4 ;
    h.try(:flatten)
  }
}
" > log/reflatten.log &
tail -f log/reflatten.log log/production.log

resource.hierarchy.hierarchy_entries.where(depth: 4).first.ancestors.size == 4

# #259 - Looking for bad merges, where one concept has multiple entries OF
# DIFFERENT RANKS (and names) from the same hierarchy

q_select = %q{SELECT DISTINCT he.taxon_concept_id page, he.id id_1,
  n.string name_1, he.depth depth_1, he.rank_id rank_1, other.id id_2,
  o_n.string name_2, other.depth depth_2, other.rank_id rank_2 }
q_out = %q{  INTO OUTFILE "/var/lib/mysql/bad_merges_HIERID.csv"
  FIELDS TERMINATED BY ','
  OPTIONALLY ENCLOSED BY '"'
  LINES TERMINATED BY '\\n' }
q_from = %q{
  FROM hierarchy_entries he
  JOIN names n ON (he.name_id = n.id)
  JOIN hierarchies h ON (he.hierarchy_id = h.id)
  LEFT JOIN hierarchy_entries other
    ON (he.taxon_concept_id = other.taxon_concept_id
      AND he.hierarchy_id = HIERID
      AND he.id != other.id
      AND other.published = 1 AND other.visibility_id = 1
      AND (he.rank_id != other.rank_id OR he.depth != other.depth))
  JOIN names o_n ON (other.name_id = o_n.id)
WHERE o_n.string != n.string AND he.published = 1 AND he.visibility_id = 1
ORDER BY he.taxon_concept_id, he.id, other.id }

hiers = Set.new ; events = HarvestEvent.complete.published.includes(resource: :hierarchy).all ; events.each { |e| hiers <<
 e.resource.hierarchy if e.resource.try :hierarchy } ; 1
conn = ActiveRecord::Base.connection ; 1

hiers.each do |hierarchy|
  begin
    q = (q_select + q_from).gsub(/HIERID/m, hierarchy.id.to_s) ; 1
    result = conn.execute(q) ; 1
    if result.size == 0
      puts "No conflicts in hierarchy #{hierarchy.id} (#{hierarchy.label})"
      next
    else
      puts "Okay, #{result.size} results in #{hierarchy.id} (#{hierarchy.label})"
      # result.each_with_index { |r,i| puts r.to_csv ; break if i > 100 }
      lbl = hierarchy.label.sub(/[^ \w].*$/, "").sub(/\s$/, "").sub(/\s/, "_").downcase
      CSV.open("log/bad_merge_candidates_#{hierarchy.id}_#{lbl}.csv", "wb") do |csv|
        csv << %w(page_id entry1_id entry1_name entry1_depth
          entry1_rank_id entry2_id entry2_name entry2_depth entry2_rank_id)
        result.each { |r| csv << r }
      end ; 1
    end
  rescue => e
    puts "GAH! #{e.message} from hierarchy #{hierarchy.id} (#{hierarchy.label})"
  end
end ; 1

# - errr... later

Benchmark.measure { Resource.find(958).relate }

concept = TaxonConcept.find 4327143
(genus, species) = concept.hierarchy_entries.where(hierarchy_id: 464)
sim = Hierarchy::Similarity.new
# sim.compare(genus, species)
entries = concept.hierarchy_entries
# results = []
# entries.each { |entry| next if entry == species ; hash = entry.from_solr.first ; next if hash.nil? ; results << sim.compare(species, hash) }
# results.each { |r| puts r.inspect } ; 1

# -- https://github.com/EOL/tramea/issues/239 part 3 - re-merging split entries...

pairs = IO.readlines("/app/log/pairs.txt")
split_entries = Set.new
pairs.each_with_index do |line, index|
  line.chomp!
  begin
    next unless line =~ /-(\d+)\D+-(\d+)/
    id1 = $1
    id2 = $2
    entry1 = HierarchyEntry.find(id1)
    entry2 = HierarchyEntry.find(id2)
    concept = entry1.taxon_concept
    if entry1.taxon_concept_id != entry2.taxon_concept_id
      (safer, split) = [entry1, entry2].sort_by { |e| e.taxon_concept_id }
      split_entries << split
    end
  rescue => e
    puts "Yuck, bad UTF8"
  end
end

grouped = split_entries.to_a.group_by { |e| e.hierarchy_id }
grouped_ids = {}
grouped.each { |k,v| grouped_ids[k] = v.map(&:id) } ; 1

grouped_ids.each do |hierarchy_id, ids|
  hierarchy = Hierarchy.find(hierarchy_id)
  hierarchy.reindex_and_merge_ids(ids)
end

# -- https://github.com/EOL/tramea/issues/239 part 2 - pulling apart entries

@user = User.find(20470)
pairs = IO.readlines("/app/log/pairs.txt")

splits = {}
@lines = {}
pairs.each_with_index do |line, index|
  line.chomp!
  EOL.log("#{index}") if index % 500 == 0
  begin
    next unless line =~ /-(\d+)\D+-(\d+)/
    id1 = $1
    id2 = $2
    entry1 = HierarchyEntry.includes(name: { canonical_form: :name }).find(id1)
    entry2 = HierarchyEntry.includes(name: { canonical_form: :name }).find(id2)
    concept = entry1.taxon_concept
    if entry1.taxon_concept_id != entry2.taxon_concept_id
      EOL.log("NOT THE SAME CONCEPT: #{line}")
      next
    end
    splits[concept] ||= Set.new
    splits[concept] += [entry1, entry2]
    @lines[concept] ||= Set.new
    @lines[concept] << line
  rescue => e
    EOL.log("OOPS: #{line}")
    EOL.log_error(e) # Usually UTF-8 PROBLEMS
  end
end

def problem(concept)
  EOL.log("Affected lines:")
  @lines[concept].each do |line|
    EOL.log("  #{line}")
  end
end

splits.each do |concept, entries|
  sorted = entries.sort_by { |e| e.name.try(:canonical_form).try(:string) }
  if sorted.include?(nil)
    EOL.log("ERROR: Missing a name on concept #{concept.id}.")
    problem(concept)
    next
  end
  name1 = sorted[0].name.try(:canonical_form).try(:string)
  # name2 = sorted[1].name.try(:canonical_form).try(:string)
  # if name1.length == name2.length
  #   names = entries.map { |e| e.name.try(:canonical_form).try(:string) }
  #   EOL.log("ERROR: Same length: {#{name1}} and {#{name2}}")
  #   problem(concept)
  #   next
  # end
  exemplar_id = sorted[0].id
  index = sorted.index { |e| e.name.try(:canonical_form).try(:string).length > name1.length }
  if index.nil?
    EOL.log("ERROR: Couldn't find a longer name")
    problem(concept)
    next
  end
  other_ids = sorted[index..-1].map(&:id)
  begin
    concept.split_classifications(other_ids, user: @user, exemplar_id: exemplar_id)
  rescue EOL::Exceptions::ClassificationsLocked => e
    EOL.log("ERROR: LOCKED CLASSIFICATION (TC ##{concept.id}):")
    problem(concept)
    next
  rescue EOL::Exceptions::TooManyDescendantsToCurate => e
    EOL.log("ERROR: TOO BIG: #{line}")
    problem(concept)
    next
  rescue => e
    EOL.log("ERROR: MISC... #{line}")
    EOL.log_error(e)
    problem(concept)
    next
  end
  sleep(3)
end

# -- https://github.com/EOL/tramea/issues/239

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
        name1 = entry1.name.try(:canonical_form).try(:string) || "No name! (really)"
        name2 = entry2.name.try(:canonical_form).try(:string) || "No name! (really)"
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
