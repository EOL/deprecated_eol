# This is a scenario to simulate a bunch of activity with comunities and users, to demonstrate searching capabilities within
# those concepts. It builds on the bootstrap scenario, to re-use a few of its concepts.
#
#---
#dependencies: [ :foundation, :bootstrap ]

require 'spec/eol_spec_helpers'
require 'spec/scenario_helpers'
# This gives us the ability to build taxon concepts:
include EOL::Spec::Helpers

activity = {}

# NOTE - a lof of the strings from bootstrap are hard-coded, rather than stored as TestInfo.  TODO - move them.
# ...for the time-being, I will just prentend I know all of the names in bootrstap.  TODO - re-use the TestInfo from bootstrap

activity[:user_names] = ['jsmith', 'bbrown', 'jade', 'veets', 'jrice', 'dima', 'pleary', 'klans', 'lisa', 'wilson']
activity[:taxa] = {
  'brownbird' => build_ta
activity[:community_names] = [
  'brown birds' => {:taxa => ['brownbird', 'crow', 'waxwing']},
  'green plants' => {:taxa => ['lettuce', 'celery', 'broccoli', 'spinach']},
  'tasty mushrooms' => {:taxa => ['amanita', 'button', 'shitaki']},
  'fun stuff' => {:taxa => ['cat', 'dog']},
  'my backyard' => {:taxa => ['pine tree', 'douglass fir', 'dog']},
  'leafy vegetables' => {:taxa => ['lettuce', 'spinach']},
  'juicy fruit' => {:taxa => ['apple', 'orange', 'mango', 'kiwi']},
  'scary animals' => {:taxa => ['clown', 'snake', 'wolverine']},
  'in my garden' => {:taxa => ['lilly', 'rose', 'carrot']},
  'endangered birds' => {:taxa => ['piping plover', 'albatross']}
]

activity[:users] = []
activity[:communities] = []
activity[:owners] = []

activity[:user_names].each do |name|
  activity[:users] << User.gen(:username => name)
end

activity[:community_names].keys.each do |name|
  owner = User.gen
  activity[:communities] << Community.gen(:name => name)
  activity[:communities].last.initialize_as_created_by(owner)
  activity[:owners] << owner
  activity[:community_names][name][:taxa].each do |common_name|
    community.focus.add build_taxon_concept(:common_name => common_name)
  end
end

# We'll have each user join the community in its parallel array:
activity[:users].each_with_index do |user, i|
  user.join_community(activity[:communities][i])
end

# We want one user who's in every community:
activity[:busy_user] = User.gen(:username => 'busy')

activity[:communities].each do |community|
  activity[:busy_user].join_community(community)
end

# We want another user who has joined and left every community (ie: they are not a member of any of them by the end)
activity[:fickle_user] = User.gen(:username => 'fickle')

activity[:communities].each do |community|
  activity[:busy_user].join_community(community)
  activity[:busy_user].leave_community(community)
end



EOL::TestInfo.save('community_activity', activity)
