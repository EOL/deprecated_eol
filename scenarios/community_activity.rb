# This is a scenario to simulate a bunch of activity with comunities and users, to demonstrate searching capabilities
# within those concepts. It builds on the bootstrap scenario, to re-use a few of its concepts.

require Rails.root.join('spec', 'scenario_helpers')
# This gives us the ability to build taxon concepts:
include EOL::Builders
include ScenarioHelpers # Allows us to load other scenarios

load_foundation_cache

ActiveRecord::Base.transaction do
  data = {}

  # NOTE - a lof of the strings from bootstrap are hard-coded, rather than stored as TestInfo.  TODO - move them.
  # ...for the time-being, I will just prentend I know all of the names in bootrstap.  TODO - re-use the TestInfo from bootstrap

  data[:user_names] = ['jsmith', 'bbrown', 'jade', 'veets', 'jrice', 'dima', 'pleary', 'klans', 'lisa', 'wilson']
  # A BUNCH of taxa to build communities and collections from (and search on)
  data[:taxa_ids] = {
    :brownbird => build_taxon_concept(:common_name => 'brownbird', comments: [], toc: [], bhl: [], 
                                      images: [], sounds: [], youtube: [], flash: []).id,
    :crow => build_taxon_concept(:common_name => 'crow', comments: [], toc: [], bhl: [], 
                                 images: [], sounds: [], youtube: [], flash: []).id,
    :waxwing => build_taxon_concept(:common_name => 'waxwing', comments: [], toc: [], bhl: [], 
                                    images: [], sounds: [], youtube: [], flash: []).id,
    :lettuce => build_taxon_concept(:common_name => 'lettuce', comments: [], toc: [], bhl: [], 
                                    images: [], sounds: [], youtube: [], flash: []).id,
    :celery => build_taxon_concept(:common_name => 'celery', comments: [], toc: [], bhl: [], 
                                   images: [], sounds: [], youtube: [], flash: []).id,
    :broccoli => build_taxon_concept(:common_name => 'broccoli', comments: [], toc: [], bhl: [], 
                                     images: [], sounds: [], youtube: [], flash: []).id,
    :spinach => build_taxon_concept(:common_name => 'spinach', comments: [], toc: [], bhl: [], 
                                    images: [], sounds: [], youtube: [], flash: []).id,
    :amanita => build_taxon_concept(:common_name => 'amanita', comments: [], toc: [], bhl: [], 
                                    images: [], sounds: [], youtube: [], flash: []).id,
    :button => build_taxon_concept(:common_name => 'button mushroom', comments: [], toc: [], bhl: [], 
                                   images: [], sounds: [], youtube: [], flash: []).id,
    :shitaki => build_taxon_concept(:common_name => 'shitaki', comments: [], toc: [], bhl: [], 
                                    images: [], sounds: [], youtube: [], flash: []).id,
    :cat => build_taxon_concept(:common_name => 'cat', comments: [], toc: [], bhl: [], 
                                images: [], sounds: [], youtube: [], flash: []).id,
    :dog => build_taxon_concept(:common_name => 'dog', comments: [], toc: [], bhl: [], 
                                images: [], sounds: [], youtube: [], flash: []).id,
    :pine_tree => build_taxon_concept(:common_name => 'pine_tree', comments: [], toc: [], bhl: [], 
                                      images: [], sounds: [], youtube: [], flash: []).id,
    :douglas_fir => build_taxon_concept(:common_name => 'douglas fir', comments: [], toc: [], bhl: [], 
                                        images: [], sounds: [], youtube: [], flash: []).id,
    :apple => build_taxon_concept(:common_name => 'apple', comments: [], toc: [], bhl: [], 
                                  images: [], sounds: [], youtube: [], flash: []).id,
    :orange => build_taxon_concept(:common_name => 'orange', comments: [], toc: [], bhl: [], 
                                   images: [], sounds: [], youtube: [], flash: []).id,
    :mango => build_taxon_concept(:common_name => 'mango', comments: [], toc: [], bhl: [], 
                                  images: [], sounds: [], youtube: [], flash: []).id,
    :kiwi => build_taxon_concept(:common_name => 'kiwi', comments: [], toc: [], bhl: [], 
                                 images: [], sounds: [], youtube: [], flash: []).id,
    :clown => build_taxon_concept(:common_name => 'clown', comments: [], toc: [], bhl: [], 
                                  images: [], sounds: [], youtube: [], flash: []).id,
    :snake => build_taxon_concept(:common_name => 'snake', comments: [], toc: [], bhl: [], 
                                  images: [], sounds: [], youtube: [], flash: []).id,
    :wolverine => build_taxon_concept(:common_name => 'wolverine', comments: [], toc: [], bhl: [], 
                                      images: [], sounds: [], youtube: [], flash: []).id,
    :lilly => build_taxon_concept(:common_name => 'lilly', comments: [], toc: [], bhl: [], 
                                  images: [], sounds: [], youtube: [], flash: []).id,
    :rose => build_taxon_concept(:common_name => 'rose', comments: [], toc: [], bhl: [], 
                                 images: [], sounds: [], youtube: [], flash: []).id,
    :carrot => build_taxon_concept(:common_name => 'carrot', comments: [], toc: [], bhl: [], 
                                   images: [], sounds: [], youtube: [], flash: []).id,
    :piping_plover => build_taxon_concept(:common_name => 'piping plover', comments: [], toc: [], bhl: [], 
                                          images: [], sounds: [], youtube: [], flash: []).id,
    :albatross => build_taxon_concept(:common_name => 'albatross', comments: [], toc: [], bhl: [], 
                                      images: [], sounds: [], youtube: [], flash: []).id
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
      data[:communities].last.collections.first.add TaxonConcept.find(id)
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
    user = data[:users].sample(1).first
    community = data[:communities].sample(1).first
    body = "This is a comment from #{user.username} on #{community.name}"
    Comment.gen(:parent => community, :body => body, :user => user)
    data[:comments] << {:user_id => user.id, :target_class => 'Community', :target_id => community.id, :body => body}
  end

  # Have a few users comment on taxa:
  10.times do
    user = data[:users].sample(1).first
    community = data[:communities].sample(1).first
    taxon = community.collections.first.collection_items.sample(1).first.collected_item
    body = "This is a comment from #{user.username} on #{taxon.preferred_common_name_in_language(Language.default)}"
    Comment.gen(:parent => taxon, :body => body, :user => user)
    data[:comments] << {:user_id => user.id, :target_class => 'TaxonConcept', :target_id => taxon.id, :body => body}
  end

  CuratorLevel.create_enumerated

  # TODO - make a curator.  Have him comment on his taxa and on NOT his taxa.
  # TODO - have the curator curate some stuff: hide/show, hide, trust, untrust, unreview.

  EOL::TestInfo.save('community_activity', data)
end