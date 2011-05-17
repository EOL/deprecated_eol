# So this just loads a taxon with lots and lots of images, videos, and sounds.
#
#---
#dependencies: [ :foundation ]

require 'spec/eol_spec_helpers'
require 'spec/scenario_helpers'
# This gives us the ability to build taxon concepts:
include EOL::Spec::Helpers

puts "*" * 100
puts "Community special: #{Community.special.id}"

data = {}

data[:canonical_form] = 'Copious picturesqus'
data[:common_name]    = 'Snappy'
images = []
videos = []
50.times { images << {} } # TODO -random ratings
20.times { videos << {} }
data[:taxon_concept] = build_taxon_concept(:canonical_form => data[:canonical_form], :common_name => data[:common_name],
                                           :images => images, :videos => videos)

data[:taxon_concept_id] = data[:taxon_concept].id

EOL::TestInfo.save('media_heavy', data)
