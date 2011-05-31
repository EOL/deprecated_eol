# Creates a few named and numbered entries in the table with specific data expected to be encountered during a demo
# for potential funding sources.  Showcases feeds, communities, and collections.
#
# Note that this does NOT include prerequisite scenarios.  It is intended to run against a staging/integration style
# database and running foundation or the like would be... very, very bad.  (foundation truncates tables.)
#
# Please be very, very careful loading scenarios against large databases.

taxa_ids_to_use = [2866150, 17924149, 921737, 328607, 1061748, 491753]
taxa = taxa_ids_to_use.map {|id| TaxonConcept.find(id)}

community_owner = User.find(1)
community = Community.gen(:name => 'EOL V2 Demo', :description => 'This is a community intended to showcase the newest features of Version 2 for the EOL website.')
community.initialize_as_created_by(community_owner)

collection_owner = User.find(2)
endorsed_collection = Collection.gen(:user => collection_owner, :name => 'New Species from the Census of Marine Life')

taxa.each do |tc|
  community.focus.add tc
  endorsed_collection.add tc
end
