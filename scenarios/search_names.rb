# Creates the data required to do name searches for testing.
#
# ---
# dependencies: [ :foundation ]

require 'spec/eol_spec_helpers'
require 'spec/scenario_helpers'
# This gives us the ability to build taxon concepts:
include EOL::Spec::Helpers

Community.special # Raises an exception if it's missing.  If that happens to you, figure out why foundation wasn't properly loaded.

results = {}

results[:panda_name] = 'panda'
results[:panda]      = build_taxon_concept(:common_names => [results[:panda_name]])
results[:tiger_name] = 'Tiger'
results[:tiger]      = build_taxon_concept(:common_names => [results[:tiger_name]], :vetted => 'untrusted')
results[:tiger_lilly_name] = "#{results[:tiger_name]} lilly"
results[:tiger_lilly]      = build_taxon_concept(:common_names => [results[:tiger_lilly_name], 'Panther tigris'],
                                                 :vetted => 'unknown')
results[:tiger_moth_name] = "#{results[:tiger_name]} moth"
results[:tiger_moth]      = build_taxon_concept(:common_names => [results[:tiger_moth_name], 'Panther moth'])
results[:plantain_name]   = 'Plantago major'
results[:plantain_common] = 'Plantain'
results[:plantain_synonym]= 'Synonymous toplantagius'
results[:plantain] = build_taxon_concept(:scientific_name => results[:plantain_name],
                                         :common_names => [results[:plantain_common]])
results[:plantain].add_scientific_name_synonym(results[:plantain_synonym])

another = build_taxon_concept(:scientific_name => "#{results[:plantain_name]} L.",
                              :common_names => ["big #{results[:plantain_common]}"])
another.add_scientific_name_synonym(results[:plantain_synonym]) # I'm only doing this so we get two results and not redirected.
SearchSuggestion.gen(:taxon_id => results[:plantain].id, :scientific_name => results[:plantain_name],
                     :term => results[:plantain_name], :common_name => results[:plantain_common])

results[:dog_name]      = 'Dog'
results[:domestic_name] = "Domestic #{results[:dog_name]}"
results[:dog_sci_name]  = 'Canis lupus familiaris'
results[:wolf_name]     = 'Wolf'
results[:wolf_sci_name] = 'Canis lupus'
results[:wolf] = build_taxon_concept(:scientific_name => results[:wolf_sci_name], :common_names => [results[:wolf_name]])
results[:dog]  = build_taxon_concept(:scientific_name => results[:dog_sci_name], :common_names => [results[:domestic_name]],
                                     :parent_hierarchy_entry_id => results[:wolf].hierarchy_entries.first.id)

SearchSuggestion.gen(:taxon_id => results[:dog].id, :term => results[:dog_name],
                     :scientific_name => results[:dog].scientific_name,
                     :common_name => results[:dog].common_name)
SearchSuggestion.gen(:taxon_id => results[:wolf].id, :term => results[:dog_name],
                     :scientific_name => results[:wolf].scientific_name,
                     :common_name => results[:wolf].common_name)

results[:tricky_search_suggestion] = 'Bacteria'
results[:bacteria_common] = results[:tricky_search_suggestion]
results[:bacteria] = build_taxon_concept(:scientific_name => results[:tricky_search_suggestion],
                                         :common_names => [results[:bacteria_common]])
SearchSuggestion.gen(:taxon_id => results[:bacteria].id, :scientific_name => results[:tricky_search_suggestion],
                     :term => results[:tricky_search_suggestion], :common_name => results[:bacteria_common])

# I'm only doing this so we get two results and not redirected.
build_taxon_concept(:scientific_name => results[:tricky_search_suggestion])

EOL::TestInfo.save('search_names', results)
