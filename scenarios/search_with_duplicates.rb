# Creates the very minimal set of data needed to conduct a search (for 'tiger')(for 'tiger')  that includes duplicate results.
#
#   TODO add a description here of what actually gets created!
#
#   This description block can be viewed (as well as other information
#   about this scenario) by running:
#     $ rake scenarios:show NAME=bootstrap
#
# ---
# dependencies: [ :foundation ]

require 'spec/scenario_helpers'
# This gives us the ability to recalculate some DB values:
include EOL::Data
# This gives us the ability to build taxon concepts:
include EOL::Builders

results = {}

results[:tc_id] = 255
results[:old_common_name] = 'Old Common Name'
results[:new_common_name] = 'New Common Name'
results[:parent_common_name] = 'Parent Name'
results[:ancestor_common_name] = 'Ancestor Name'
results[:ancestor_concept] = build_taxon_concept(:common_names => [results[:ancestor_common_name]])
results[:parent_concept] = build_taxon_concept(:common_names => [results[:parent_common_name]],
                                      :parent_hierarchy_entry_id => results[:ancestor_concept].entry.id)
results[:taxon_concept] = build_taxon_concept(:id => results[:tc_id], :common_names => [results[:new_common_name]],
                                     :parent_hierarchy_entry_id => results[:parent_concept].entry.id)
results[:new_hierarchy_id] = Hierarchy.gen.id
results[:duplicate_taxon_concept] = build_taxon_concept(:hierarchy => results[:new_hierarchy], :common_names => [results[:new_common_name]])

results[:query_results] = [
 {"common_name"=>["tiger"],
  "top_image_id"=>66,
  "preferred_scientific_name"=>["Nonnumquamerus numquamerus L."],
  "published"=>[true],
  "scientific_name"=>["Nonnumquamerus numquamerus L."],
  "supercedure_id"=>[0],
  "vetted_id"=>[3],
  "taxon_concept_id"=>[25]} ,
 {"common_name"=>[results[:old_common_name]],
  "top_image_id"=>nil,
  "preferred_scientific_name"=>["Estveroalia nihilata L."],
  "published"=>[true],
  "scientific_name"=>["Estveroalia nihilata L."],
  "supercedure_id"=>[0],
  "vetted_id"=>[0],
  "taxon_concept_id"=>[results[:tc_id]]},
 {"common_name"=>[results[:old_common_name]],
  "top_image_id"=>nil,
  "preferred_scientific_name"=>["Estveroalia nihilata L."],
  "published"=>[true],
  "scientific_name"=>["Estveroalia nihilata L."],
  "supercedure_id"=>[0],
  "vetted_id"=>[0],
  "taxon_concept_id"=>[results[:duplicate_taxon_concept].id]},
 {"common_name"=>["Tiger moth"],
  "top_image_id"=>51,
  "preferred_scientific_name"=>["Autvoluptatesus temporaalis Linn"],
  "published"=>[true],
  "scientific_name"=>["Autvoluptatesus temporaalis Linn"],
  "supercedure_id"=>[0],
  "vetted_id"=>[3],
  "taxon_concept_id"=>[26]},
 {"common_name"=>["Tiger lilly"],
  "top_image_id"=>nil,
  "preferred_scientific_name"=>["Excepturialia omnisa R. Cartwright"],
  "published"=>[true],
  "scientific_name"=>["Excepturialia omnisa R. Cartwright"],
  "supercedure_id"=>[0],
  "vetted_id"=>[2],
  "taxon_concept_id"=>[27]}
]

EOL::TestInfo.save('search_with_duplicates', results)
