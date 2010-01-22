#
# To load this scenario:
# rake truncate && rake scenarios:load NAME=foundation,search_data
#
require Rails.root + '/lib/eol_data'
class EOL::NestedSet; end
EOL::NestedSet.send :extend, EOL::Data

require 'spec/eol_spec_helpers'
# This gives us the ability to recalculate some DB values:
include EOL::Data
# This gives us the ability to build taxon concepts:
include EOL::Spec::Helpers

def animal_kingdom
  @animal_kingdom ||= build_taxon_concept(:canonical_form => 'Animals',
                                          :parent_hierarchy_entry_id => 0,
                                          :depth => 0)
end

def nestify_everything_properly
  # for each Hierarchy, go and set the lft/rgt on all of this child nodes properly
  EOL::NestedSet.make_all_nested_sets
end

def create_taxa(namestring)
  taxa = build_taxon_concept(:canonical_form => namestring, :depth => 1,
                             :parent_hierarchy_entry_id => animal_kingdom.hierarchy_entries.first.id)
  nestify_everything_properly
  return taxa
end

create_taxa('Tiger Alpha')
create_taxa('Tiger Beta')
create_taxa('Tiger Gamma')
create_taxa('Tiger Delta')
create_taxa('Tiger Epislon')
create_taxa('Tiger Zeta')
create_taxa('Tiger Eta')
create_taxa('Tiger Theta')
create_taxa('Tiger Iota')
create_taxa('Tiger Kappa')
create_taxa('Tiger Lambda')
create_taxa('Tiger Uppercut')