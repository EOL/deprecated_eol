# Creates a few named and numbered entries in the table with specific data expected to be encountered during a demo
# for potential funding sources.  Showcases feeds, communities, and collections.
#
# Note that this does NOT include prerequisite scenarios.  It is intended to run against a staging/integration style
# database and running foundation or the like would be... very, very bad.  (foundation truncates tables.)
#
# Please be very, very careful loading scenarios against large databases.

require 'spec/eol_spec_helpers'
require 'spec/scenario_helpers'
# This gives us the ability to recalculate some DB values:
include EOL::Data
# This gives us the ability to build taxon concepts:
include EOL::Spec::Helpers


def next_image
  @total_test_images = 8
  @image_number ||= 4
  @image_number = (@image_number + 1) % @total_test_images
  1000 + @image_number
end


# We need to build the taxa, if they don't exist:
taxa = []

species = [
  {
    :id => 5559,
    :depth => 1,
    :sci => 'Fungi',
    :common => 'Mushrooms, sac fungi, lichens, yeast, molds, rusts, etc.',
    :rank => 'kingdom'},
  {
    :id => 1,
    :depth => 1,
    :sci => 'Animalia',
    :common => 'Animals',
    :rank => 'kingdom'},
  {
    :id => 3352,
    :depth => 1,
    :sci => 'Chromista',
    :rank => 'kingdom'},
  {
    :id => 281,
    :depth => 1,
    :sci => 'Plantae',
    :common => 'Plants',
    :rank => 'kingdom'},
  { :id => 2861424, :depth => 5, :parent => 5559, :sci => 'Amanitaceae', :rank => 'family' },
  { :id => 18878, :depth => 4, :parent => 2861424, :sci => 'Amanita', :rank => 'genus' },
  { :id => 7160, :depth => 5, :parent => 1, :sci => 'Nephropidae', :rank => 'family' },
  { :id => 17954507, :depth => 5, :parent => 7160, :sci => 'Dinochelus', :rank => 'genus' },
  { :id => 3594, :depth => 4, :parent => 3352, :sci => 'Raphidophyceae', :rank => 'family' },
  { :id => 89513, :depth => 5, :parent => 3594, :sci => 'Haramonas', :rank => 'genus' },
  { :id => 7676, :depth => 4, :parent => 1, :sci => 'Canidae', :common => 'Coyotes, dogs, foxes, jackals, and wolves', :rank => 'family' },
  { :id => 14460, :depth => 5, :parent => 7676, :sci => 'Canis', :common => 'Wolf', :rank => 'species', :rank => 'genus' },
  { :id => 6747, :depth => 4, :parent => 281, :sci => 'Pinaceae ', :common => 'Pine trees', :rank => 'family' },
  { :id => 14031, :depth => 5, :parent => 6747, :sci => 'Pinus ', :common => 'Pine', :rank => 'genus' },
  { :id => 699, :depth => 4, :parent => 1, :sci => 'Formicidae', :rank => 'family' },
  { :id => 49148, :depth => 5, :parent => 699, :sci => 'Anochetus', :rank => 'genus' },
  { :id => 2866150, :parent => 18878,
    :sci => 'Amanita muscaria',
    :attribution => '(L. ex Fr.) Hook.',
    :common => 'Fly Agaric',
    :imgs => [201008242207638, 201101141341094, 201101141330049, 201101141305714],
    :summary => '<p>Commonly known as the fly agaric or fly Amanita, Amanita muscaria is a mycorrhizal basidiomycete
    fungus that contains several toxic, psychoactive compounds. Amanita muscaria is the typical “toadstool” mushroom,
    bearing white gills and white warts on its variably colored cap and growing typically in clusters near conifers
  or hardwoods throughout the northern hemisphere</p><p>The name fly agaric comes from its use as a control for pesky flies. The old practice was to soaking pieces of
  the mushroom in a saucer of milk to attract flies. The flies would drink the tainted milk, become intoxicated, and
  fly into walls to their death.</p>',
    :rank => 'species'},
  { :id => 17924149, :parent => 17954507,
    :sci => 'Dinochelus ausubeli',
    :attribution => 'Ahyong, Chan & Bouchet, 2010',
    :common => "Ausubel's Mighty Claws Lobster",
    :imgs => [201012041086784, 201009280303944],
    :summary => 'Dinochelus ausubeli is a new species of deepwater lobster (family Nephropidae) first collected in
    2007 from the Philippine Sea off the island of Luzon and was formally described in 2010. The species is so
  distinct that it was not only described as a new species but placed in a newly erected genus as well (Dinochelus).
    "Dinochelus" is derived from the Greek dinos, meaning "terrible", and chela, meaning "claw", an allusion to the
  massive, spinose major claw. The specific epithet ausubeli honors Jesse Ausubel, an enthusiastic sponsor of the
  Census of Marine Life, a major effort to document marine life in the first decade of the 21st century. (Ahyong et al. 2010)',
    :rank => 'species'},
  { :id => 921737, :parent => 89513,
    :sci => 'Haramonas dimorpha',
    :attribution => 'Horiguchi',
    :imgs => [200812102137415, 200812102183535],
    :summary => 'Haramonas (ha-ra-moan-ass) dimorpha, large raphidophyte, with two emergent flagella, anterior
    flagellum beats with an undulating pattern, posterior flagellum trails. Many small green or yellow green
  plastids. No eyespot. Phase contrast microscopy.',
    :rank => 'species'},
  { :id => 328607, :parent => 14460,
    :sci => 'Canis lupus',
    :attribution => 'Linnaeus, 1758',
    :common => 'Wolf',
    :imgs => [200908250179632, 200905130150563, 200905130192503, 200907241171232],
    :summary => %q{<p>Gray wolves usually live in packs, led by an "alpha pair." The pack includes some of the alpha
    pair's offspring and may include some unrelated wolves. A pack's territory can be as large as 13,000 square km.
    Howling probably helps advertise who "owns" a particular piece of territory. When pups are born, the mother stays
  near them for the first three weeks, and her mate and others in the pack bring food to her. The pups are weaned
    when they about nine weeks old. As adults, they may travel as far as 72 km a day with their pack and run as fast
      as 70 km per hour.</p><p>
        Adaptation: This transparent view of the wolf braincase shows how the brain is situated within. The large
        feature projecting from the front of the brain is the olfactory lobe, an important center related to the
        sense of smell.</p>},
    :rank => 'species'},
  { :id => 1061748, :parent => 14031,
    :sci => 'Pinus strobus',
    :attribution => 'L.',
    :common => 'Eastern white pine',
    :imgs => [201105312325504, 201102040505636, 201102040570574, 201105132311043],
    :summary => '<p>Pinus strobus, the Eastern White Pine, is characterized by fascicles of 5 fine needles with a
    nonpersistent bundle sheath, and relatively soft, unarmed, elongate seed cones whose scales are spread at
  maturity. The native range of eastern white pine stretches from southeastern Manitoba to Newfoundland in Canada and
  from Minnesota and Iowa eastward to Maine and Pennsylvania, with a southward Appalachian extension to Tennessee and
  Georgia and isolated occurrences in western Kentucky, Illinois, and Indiana. The species also has become
  naturalized from plantings, both within its historical range and elsewhere, including portions of Europe, Asia, New
  Zealand, and Australia. A related taxon in portions of southern Mexico and Guatemala is sometimes treated as Pinus
  strobus var. chiapensis, but more often as a distinct species, Pinus chiapensis.
</p><p>
  Natural stands of Pinus strobus occur in a variety of habitats, ranging from dune forests to bogs and mixed
  conifer/hardwood forests. The species also colonizes old fields and other former agricultural lands that are
  reverting back to forests. It has been planted extensively in plantations and is also used to revegetate mine
  spoils. The species also is cultivated commonly as a shade and ornamental tree
</p><p>
  Eastern White Pine is an important timber tree for the production of softwood lumber. The wood is used for
  construction, cabinetry and furniture-making, handcrafts, and various other woodworking. Native American tribes
  used it extensively for various medicinal properties and it is an important food source for wildlife. The long
  history of cultivation has led to the development of numerous cultivars and forms. The species is affected by the
  exotic white pine blister rust Cronartium ribicola, an important pathogen of timber trees in the white pine group
  in temperate North America.</p>',
    :rank => 'species'},
  { :id => 491753, :parent => 49148,
    :sci => 'Anochetus mayri',
    :attribution => 'Emery, 1884',
    :imgs => [200901131343523, 200901131383455, 200901131367550, 201012100375791],
    :summary => 'Anochetus are presumably predators, using their snapping mandibles much like their larger relatives,
    Odontomachus. However, there are few direct observations. "A. mayri is found mostly in forests under stones, in
    moss on rocks or logs, in rotten twigs on the forest floor, or in larger bodies of rotten wood. The workers and
    queen feign death, and are difficult to see (Brown 1978)." There appear to be two distinct forms in the Atlantic
    lowlands of Costa Rica, one of which may be more arboreal (see below).',
    :rank => 'species'}
]

animalia_entry = TaxonConcept.find(1).entry.id
overv = TocItem.find_by_translated(:label, 'Brief Summary')

species.each_with_index do |info, which|
  puts which
  id = info[:id]
  tc = nil
  begin
    tc = TaxonConcept.find(id)
    puts "** FOUND #{info[:sci]} (#{id})..."
  rescue => e
    puts e.message
    parent = info.has_key?(:parent) ?
      TaxonConcept.find(info[:parent]).entry.id :
      animalia_entry
    desc = info.has_key?(:summary) ?
      info[:summary] :
      'Just a placeholder text for the description of this species'
    imgs = []
    if info.has_key? :imgs
      info[:imgs].each do |i|
        imgs << {:object_cache_url => i}
      end
    end
    commons = [info[:common]].compact
    puts "** Building #{info[:sci]} (#{id})..."
    tc = build_taxon_concept(
      :id => id,
      :parent_hierarchy_entry_id => parent,
      :canonical_form => info[:sci],
      :attribution => info[:attribution] || '',
      :common_names => commons,
      :depth => info[:depth] || nil,
      :rank => info[:rank] || nil,
      :flash => [],
      :youtube => [],
      :toc => [{ :toc_item => overv, :description => desc }],
      :images => imgs
    )
  end
  taxa << tc if info.has_key?(:summary)
  if info[:depth] == 1
    entry = tc.entry
    entry.parent_id = 0 # I hope this makes it NOT under animalia!
    entry.save!
  end
end

# Special: we want to ensure that TC 1 is really called "Animalia".  A little harsh, but:
animalia = TaxonConcept.find(1)
obj = animalia.canonical_form_object
obj.string = "Animalia"
obj.save!
obj = Name.find(animalia.entry.name_id)
obj.string = "Animalia"
obj.clean_name = 'animalia'
obj.italicized = '<i>Animalia</i>'
obj.save!

community_owner = User.first
community_owner.logo_cache_url = 1003
community_owner.save

community_name = 'Columbia Intro Biology'
community = Community.find_by_name(community_name)
community ||= Community.gen(:name => community_name, :description => 'This is a community intended to showcase the newest features of Version 2 for the EOL website.', :logo_cache_url => 2000)
community.initialize_as_created_by(community_owner)
com_col = community.focus
com_col.logo_cache_url = 2001
com_col.save!

collection_owner = User.find(community_owner.id + 1)
collection_owner.logo_cache_url = 1005
collection_owner.save

collection_name  = 'New Species from the Census of Marine Life'
endorsed_collection = Collection.find_by_name(collection_name)
endorsed_collection ||= Collection.gen(:user => collection_owner, :name => collection_name, :logo_cache_url => 3000)

# Empty the two collections:
community.focus.collection_items.each do |ci|
  ci.destroy
end
endorsed_collection.collection_items.each do |ci|
  ci.destroy
end

loud_user = User.find(community_owner.id + 2)
loud_user.logo_cache_url = 1001
loud_user.save
happy_user = User.find(community_owner.id + 3)
happy_user.logo_cache_url = 1002
happy_user.save
concerned = User.find(community_owner.id + 4)
concerned.logo_cache_url = 1003
concerned.save

# Now build them up again:
taxa.each do |tc|
  community.focus.add tc
  endorsed_collection.add tc
  # TODO - ActivityLog
end

# TODO - ActivityLog

users = User.find(:all, :conditions => 'logo_cache_url IS NULL')
puts "Updating #{users.length} users..."
users.each_with_index do |user, i|
  puts "  #{i}" if (i % 10 == 0)
  user.logo_cache_url = next_image
  user.save
end

TaxonConcept.all.each do |tc|
  tc.save # This will save the record, thus indexing the concept with all its names
end


puts "Re-indexing.  Hang on, almost there."
make_all_nested_sets
rebuild_collection_type_nested_set
flatten_hierarchies
