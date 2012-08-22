# This is a scenario to simulate a bunch of activity with comunities and users, to demonstrate searching capabilities within
# those concepts. It builds on the bootstrap scenario, to re-use a few of its concepts.
#
#---
#dependencies: [ :foundation, :bootstrap ]

require 'spec/eol_spec_helpers'
require 'spec/scenario_helpers'
# This gives us the ability to build taxon concepts:
include EOL::RSpec::Helpers

data = {}

# NOTE - a lof of the strings from bootstrap are hard-coded, rather than stored as TestInfo.  TODO - move them.
# ...for the time-being, I will just prentend I know all of the names in bootrstap.  TODO - re-use the TestInfo from bootstrap

data[:user_names] = ['jsmith', 'bbrown', 'jade', 'veets', 'jrice', 'dima', 'pleary', 'klans', 'lisa', 'wilson']
# A BUNCH of taxa to build communities and collections from (and search on)
data[:taxa_ids] = {
  :brownbird => build_taxon_concept(:common_name => 'brownbird').id,
  :crow => build_taxon_concept(:common_name => 'crow').id,
  :waxwing => build_taxon_concept(:common_name => 'waxwing').id,
  :lettuce => build_taxon_concept(:common_name => 'lettuce').id,
  :celery => build_taxon_concept(:common_name => 'celery').id,
  :broccoli => build_taxon_concept(:common_name => 'broccoli').id,
  :spinach => build_taxon_concept(:common_name => 'spinach').id,
  :amanita => build_taxon_concept(:common_name => 'amanita').id,
  :button => build_taxon_concept(:common_name => 'button mushroom').id,
  :shitaki => build_taxon_concept(:common_name => 'shitaki').id,
  :cat => build_taxon_concept(:common_name => 'cat').id,
  :dog => build_taxon_concept(:common_name => 'dog').id,
  :pine_tree => build_taxon_concept(:common_name => 'pine_tree').id,
  :douglas_fir => build_taxon_concept(:common_name => 'douglas fir').id,
  :apple => build_taxon_concept(:common_name => 'apple').id,
  :orange => build_taxon_concept(:common_name => 'orange').id,
  :mango => build_taxon_concept(:common_name => 'mango').id,
  :kiwi => build_taxon_concept(:common_name => 'kiwi').id,
  :clown => build_taxon_concept(:common_name => 'clown').id,
  :snake => build_taxon_concept(:common_name => 'snake').id,
  :wolverine => build_taxon_concept(:common_name => 'wolverine').id,
  :lilly => build_taxon_concept(:common_name => 'lilly').id,
  :rose => build_taxon_concept(:common_name => 'rose').id,
  :carrot => build_taxon_concept(:common_name => 'carrot').id,
  :piping_plover => build_taxon_concept(:common_name => 'piping plover').id,
  :albatross => build_taxon_concept(:common_name => 'albatross').id
}

data[:community_names] = {
  'brown birds' => {:taxa_ids => [data[:taxa_ids][:brownbird], data[:taxa_ids][:crow], data[:taxa_ids][:waxwing]]},
  'green plants' => {:taxa_ids => [data[:taxa_ids][:lettuce], data[:taxa_ids][:celery], data[:taxa_ids][:broccoli], data[:taxa_ids][:spinach]]},
  'tasty mushrooms' => {:taxa_ids => [data[:taxa_ids][:amanita], data[:taxa_ids][:button], data[:taxa_ids][:shitaki]]},
  'fun stuff' => {:taxa_ids => [data[:taxa_ids][:cat], data[:taxa_ids][:dog]]},
  'my backyard' => {:taxa_ids => [data[:taxa_ids][:pine_tree], data[:taxa_ids][:douglas_fir], data[:taxa_ids][:dog]]},
  'leafy vegetables' => {:taxa_ids => [data[:taxa_ids][:lettuce], data[:taxa_ids][:spinach]]},
  'juicy fruit' => {:taxa_ids => [data[:taxa_ids][:apple], data[:taxa_ids][:orange], data[:taxa_ids][:mango], data[:taxa_ids][:kiwi]]},
  'scary animals' => {:taxa_ids => [data[:taxa_ids][:clown], data[:taxa_ids][:snake], data[:taxa_ids][:wolverine]]},
  'in my garden' => {:taxa_ids => [data[:taxa_ids][:lilly], data[:taxa_ids][:rose], data[:taxa_ids][:carrot]]},
  'endangered birds' => {:taxa_ids => [data[:taxa_ids][:piping_plover], data[:taxa_ids][:albatross]]}
}

data[:users] = []
data[:communities] = []
data[:owners] = []

data[:user_names].each do |name|
  data[:users] << User.gen(:username => name)
end

data[:community_names].keys.each do |name|
  owner = User.gen
  data[:communities] << Community.gen(:name => name)
  # Each community has its own (basically nameless) owner
  data[:communities].last.initialize_as_created_by(owner)
  data[:owners] << owner
  # And each community has a few taxa associated with it:
  data[:community_names][name][:taxa_ids].each do |id|
    data[:communities].last.focus.add TaxonConcept.find(id)
  end
end

# We'll have each user join the community in its parallel array:
data[:users].each_with_index do |user, i|
  user.join_community(data[:communities][i])
end

# We want one user who's in every community:
data[:busy_user] = User.gen(:username => 'busy')

data[:communities].each do |community|
  data[:busy_user].join_community(community)
end

# We want another user who has joined and left every community (ie: they are not a member of any of them by the end)
data[:fickle_user] = User.gen(:username => 'fickle')

data[:communities].each do |community|
  data[:fickle_user].join_community(community)
  data[:fickle_user].leave_community(community)
end

# have a few of the users comment on communities.
data[:comments] = []
10.times do
  user = data[:users].rand
  community = data[:communities].rand
  body = "This is a comment from #{user.username} on #{community.name}"
  Comment.gen(:parent => community, :body => body, :user => user)
  data[:comments] << {:user_id => user.id, :target_class => 'Community', :target_id => community.id, :body => body}
end

# Have a few users comment on taxa:
10.times do
  user = data[:users].rand
  community = data[:communities].rand
  taxon = community.focus.collection_items.rand.object
  body = "This is a comment from #{user.username} on #{taxon.common_name}"
  Comment.gen(:parent => taxon, :body => body, :user => user)
  data[:comments] << {:user_id => user.id, :target_class => 'TaxonConcept', :target_id => taxon.id, :body => body}
end

# TODO - make a curator.  Have him comment on his taxa and on NOT his taxa.
# TODO - have the curator curate some stuff: hide/show, hide, trust, untrust, unreview.

EOL::TestInfo.save('community_activity', data)
