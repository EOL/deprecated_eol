#
# To load this scenario:
# rake truncate && rake scenarios:load NAME=foundation,search_data
#
class EOL::NestedSet; end
EOL::NestedSet.send :extend, EOL::Data

# This gives us the ability to recalculate some DB values:
include EOL::Data
# This gives us the ability to build taxon concepts:
include EOL::Builders

def animal_kingdom
  @animal_kingdom ||= build_taxon_concept(:canonical_form => 'Animals',
                                          :parent_hierarchy_entry_id => 0,
                                          :depth => 0)
end

def nestify_everything_properly
  # for each Hierarchy, go and set the lft/rgt on all of this child nodes properly
  EOL::NestedSet.make_all_nested_sets
end

def create_taxon(namestring)
  taxon = build_taxon_concept(:canonical_form => namestring, :depth => 1,
                             :parent_hierarchy_entry_id => animal_kingdom.hierarchy_entries.first.id)
  nestify_everything_properly
  return taxon
end

create_taxon('Tiger Alpha')
create_taxon('Tiger Beta')
create_taxon('Tiger Gamma')
create_taxon('Tiger Delta')
create_taxon('Tiger Epislon')
create_taxon('Tiger Zeta')
create_taxon('Tiger Eta')
create_taxon('Tiger Theta')
create_taxon('Tiger Iota')
create_taxon('Tiger Kappa')
create_taxon('Tiger Lambda')
create_taxon('Tiger Uppercut')
