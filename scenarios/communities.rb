# Put a few taxa (all within a new hierarchy) in the database with a range of accoutrements
#
#   TODO add a description here of what actually gets created!
#
#   This description block can be viewed (as well as other information
#   about this scenario) by running:
#     $ rake scenarios:show NAME=bootstrap
#
#---
#dependencies: [ :foundation ]

$CACHE.clear # Not *positive* we need this, but...
require 'spec/eol_spec_helpers'
require 'spec/scenario_helpers'
# This gives us the ability to build taxon concepts:
include EOL::Spec::Helpers


load_foundation_cache

communities = {}
communities[:user_non_member] = User.gen
communities[:name_of_create_button] = 'Create'

# @community has all expected data including feeds
communities[:community] = Community.gen
communities[:user_community_administrator] = User.gen
communities[:user_community_member] = User.gen
communities[:community].initialize_as_created_by(communities[:user_community_administrator])
communities[:community_member] = communities[:community].add_member(communities[:user_community_member])
communities[:community_member].add_role Role.gen(:community => communities[:community])
communities[:feed_body_1] = "Something"
communities[:community].feed.post communities[:feed_body_1]
communities[:feed_body_2] = "Something Else"
communities[:community].feed.post communities[:feed_body_2]
communities[:feed_body_3] = "Something More"
communities[:community].feed.post communities[:feed_body_3]
communities[:tc1] = build_taxon_concept
communities[:tc2] = build_taxon_concept
communities[:community].focus.add(communities[:tc1])
communities[:community].focus.add(communities[:tc2])

# Empty community, no feeds
communities[:empty_community] = Community.gen


EOL::TestInfo.save('communities', communities)
