# Creates a few named and numbered entries in the table with specific data expected to be encountered during a demo
# for potential funding sources.  Showcases feeds, communities, and collections.
#
# Note that this does NOT include prerequisite scenarios.  It is intended to run against a staging/integration style
# database and running foundation or the like would be... very, very bad.  (foundation truncates tables.)
#
# Please be very, very careful loading scenarios against large databases.

taxa_ids_to_use = [2866150, 17924149, 921737, 328607, 1061748, 491753]
taxa_ids_to_use = [1, 8, 9, 12, 14, 16] if RAILS_ENV =~ /devel/ # If you're running this after bootstrap, you want these.
taxa = taxa_ids_to_use.map {|id| TaxonConcept.find(id)}

community_owner = User.first
community_name = 'Endangered Species of Montana'
community = Community.find_by_name(community_name)
community ||= Community.gen(:name => community_name, :description => 'This is a community intended to showcase the newest features of Version 2 for the EOL website.')
community.initialize_as_created_by(community_owner)

collection_owner = User.find(community_owner.id + 1)
collection_name  = 'New Species from the Census of Marine Life'
endorsed_collection = Collection.find_by_name(collection_name)
endorsed_collection ||= Collection.gen(:user => collection_owner, :name => collection_name)

# Empty the two collections:
community.focus.collection_items.each do |ci|
  ci.destroy
end
endorsed_collection.collection_items.each do |ci|
  ci.destroy
end

loud_user = User.find(community_owner.id + 2)
happy_user = User.find(community_owner.id + 3)
concerned = User.find(community_owner.id + 4)

# Now build them up again:
taxa.each do |tc|
  community.focus.add tc
  endorsed_collection.add tc
  tc.feed.post "#{loud_user.username} commented on #{tc.quick_scientific_name(:canonical)}: This is one of my favorite species; I am excited to see how this page grows.", :user_id => loud_user.id
  tc.feed.post "#{happy_user.username} commented on #{tc.quick_scientific_name(:canonical)}: Beautiful!", :user_id => happy_user.id
  tc.feed.post "#{concerned.username} commented on #{tc.quick_scientific_name(:canonical)}: We could really use a few more images of this in its natural habitat.", :user_id => concerned.id
end
