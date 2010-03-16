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
# arbitrary_variable: arbitrary value

require 'spec/eol_spec_helpers'
require 'spec/scenario_helpers'
# This gives us the ability to recalculate some DB values:
include EOL::Data
# This gives us the ability to build taxon concepts:
include EOL::Spec::Helpers

# Okay, I am *really* stretching things, here, by adding a class with methods to give the user a way to have the
# results they want to test against...

class SearchScenarioResults
  @@tc_id = 255
  @@old_common_name = 'Old Common Name'
  @@new_common_name = 'New Common Name'
  @@parent_common_name = 'Parent Name'
  @@ancestor_common_name = 'Ancestor Name'
  @@ancestor_concept = build_taxon_concept(:common_names => [@@ancestor_common_name])
  @@parent_concept = build_taxon_concept(:common_names => [@@parent_common_name],
                                        :parent_hierarchy_entry_id => @@ancestor_concept.entry.id)
  @@taxon_concept = build_taxon_concept(:id => @@tc_id, :common_names => [@@new_common_name],
                                       :parent_hierarchy_entry_id => @@parent_concept.entry.id)
  @@new_hierarchy = Hierarchy.gen
  @@duplicate_taxon_concept = build_taxon_concept(:hierarchy => @@new_hierarchy, :common_names => [@@new_common_name])

  class << self
    def tc_id
      return @@tc_id
    end
    def old_common_name
      return @@old_common_name
    end
    def new_common_name
      return @@new_common_name
    end
    def parent_common_name
      return @@parent_common_name
    end
    def ancestor_common_name
      return @@ancestor_common_name
    end
    def ancestor_concept
      return @@ancestor_concept
    end
    def parent_concept
      return @@parent_concept
    end
    def taxon_concept
      return @@taxon_concept
    end
    def new_hierarchy
      return @@new_hierarchy
    end
    def duplicate_taxon_concept
      return @@duplicate_taxon_concept
    end
    def query_results
      return [
       {"common_name"=>["tiger"],
        "top_image_id"=>66,
        "preferred_scientific_name"=>["Nonnumquamerus numquamerus L."],
        "published"=>[true],
        "scientific_name"=>["Nonnumquamerus numquamerus L."],
        "supercedure_id"=>[0],
        "vetted_id"=>[3],
        "taxon_concept_id"=>[25]},
       {"common_name"=>[@@old_common_name],
        "top_image_id"=>nil,
        "preferred_scientific_name"=>["Estveroalia nihilata L."],
        "published"=>[true],
        "scientific_name"=>["Estveroalia nihilata L."],
        "supercedure_id"=>[0],
        "vetted_id"=>[0],
        "taxon_concept_id"=>[@@tc_id]},
       {"common_name"=>[@@old_common_name],
        "top_image_id"=>nil,
        "preferred_scientific_name"=>["Estveroalia nihilata L."],
        "published"=>[true],
        "scientific_name"=>["Estveroalia nihilata L."],
        "supercedure_id"=>[0],
        "vetted_id"=>[0],
        "taxon_concept_id"=>[@@duplicate_taxon_concept.id]},
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
        "taxon_concept_id"=>[27]}]
    end
  end
end

