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

  10.times do
    Collection.gen
  end  

end
