# So this just loads a taxon with lots and lots of images, videos, and sounds.
# We add some random data ratings with rating range (1-5).
# We ensure that we have some unreviewed objects (default is trusted).
# We add a photosynth source_url as this is currently how photosynths are determined in the code we are testing - this is not scalable and should change.
# We add a highly ranked text object so we can test that text are excluded from media.
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
flash = []
sounds = []
youtube = []
10.times { images << { :data_rating => 1 + rand(5), :source_url => 'http://photosynth.net/identifying/by/string/is/bad/change/me' } }
10.times { images << { :data_rating => 1 + rand(5), :vetted => Vetted.unknown } }
10.times { images << { :data_rating => 1 + rand(5), :vetted => Vetted.untrusted } }
10.times { images << { :data_rating => 1 + rand(5), :vetted => Vetted.inappropriate } }
2.times { flash << { :data_rating => 1 + rand(5) } }
2.times { flash << { :data_rating => 1 + rand(5), :vetted => Vetted.unknown } }
2.times { flash << { :data_rating => 1 + rand(5), :vetted => Vetted.untrusted } }
2.times { flash << { :data_rating => 1 + rand(5), :vetted => Vetted.inappropriate } }
2.times { sounds << { :data_rating => 1 + rand(5) } }
2.times { sounds << { :data_rating => 1 + rand(5), :vetted => Vetted.unknown } }
2.times { sounds << { :data_rating => 1 + rand(5), :vetted => Vetted.untrusted } }
2.times { sounds << { :data_rating => 1 + rand(5), :vetted => Vetted.inappropriate } }
2.times { youtube << { :data_rating => 1 + rand(5), :vetted => Vetted.unknown } }

data[:taxon_concept] = build_taxon_concept(:canonical_form => data[:canonical_form], :common_name => data[:common_name],
                                           :images => images, :flash => flash, :sounds => sounds, :youtube => youtube)

EOL::TestInfo.save('media_heavy', data)
