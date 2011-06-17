# So this just loads a taxon with lots and lots of images, videos, and sounds.
#
#---
#dependencies: [ :foundation ]

require 'spec/eol_spec_helpers'
require 'spec/scenario_helpers'
# This gives us the ability to build taxon concepts:
include EOL::Spec::Helpers

data = {}

data[:canonical_form] = 'Copious picturesqus'
data[:common_name]    = 'Snappy'
images = []
videos = []

20.times { images << { :data_rating => 1 + rand(5) } }
20.times { images << { :data_rating => 1 + rand(5), :vetted => Vetted.unknown } }
20.times { videos << { :data_rating => 1 + rand(5) } }
images << { :source_url => 'http://photosynth.net/blah/blah/blah' }
images << { :data_rating => 0, :vetted => Vetted.unknown }
images << { :data_rating => 5, :vetted => Vetted.unknown }

data[:taxon_concept] = build_taxon_concept(:canonical_form => data[:canonical_form], :common_name => data[:common_name],
                                           :images => images, :videos => videos)
data[:taxon_concept_id] = data[:taxon_concept].id

EOL::TestInfo.save('media_heavy', data)
