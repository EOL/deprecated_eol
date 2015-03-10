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

Rails.cache.clear # Not *positive* we need this, but...
require Rails.root.join('spec', 'scenario_helpers')
# This gives us the ability to build taxon concepts:
include EOL::Builders
include ScenarioHelpers # Allows us to load other scenarios

load_foundation_cache

ActiveRecord::Base.transaction do
  communities = {}
  communities[:user_non_member] = User.gen
  communities[:name_of_create_button] = 'Create'

  # @community has all expected data including feeds
  communities[:community] = Community.gen
  communities[:user_community_administrator] = User.gen
  communities[:user_community_member] = User.gen
  communities[:community].initialize_as_created_by(communities[:user_community_administrator])
  communities[:community_member] = communities[:community].add_member(communities[:user_community_member])
  communities[:feed_body_1] = "Something"
  communities[:feed_body_2] = "Something Else"
  communities[:feed_body_3] = "Something More"
  communities[:tc1] = build_taxon_concept(comments: [], bhl: [], toc: [], sounds: [], images: [], youtube: [], flash: [])
  communities[:tc2] = build_taxon_concept(comments: [], bhl: [], toc: [], sounds: [], images: [], youtube: [], flash: [])
  communities[:community].focuses.first.add(communities[:tc1])
  communities[:community].focuses.first.add(communities[:tc2])

  # Empty community, no feeds
  communities[:empty_community] = Community.gen
  communities[:before_all_check] = User.gen(:username => 'communities_scenario')

  EOL::TestInfo.save('communities', communities)
end
