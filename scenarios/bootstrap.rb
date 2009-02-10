# Put a few taxa (all within a new hierarchy) in the database with a range of
# accoutrements.  Depends on foundation scenario!

# NOTE - I am not setting the mime type yet.  We never use it.
# NOTE - There are no models for all the refs_* tables, so I'm ignoring them.
def build_dato(type, desc, taxon, he = nil, options = {})
    attributes = {:data_type   => DataType.find_by_label(type),
                  :description => desc,
                  :visibility  => Visibility.visible,
                  :vetted      => Vetted.trusted,
                  # Yes, rand on all licenses is inefficient.  Lazy.  TODO ?
                  :license     => License.all.rand}
  dato = DataObject.gen(attributes.merge(options))
  DataObjectsTaxon.gen(:data_object => dato, :taxon => taxon)
  if type == 'Image'
    if dato.visibility == Visibility.visible and dato.vetted == Vetted.trusted
      TopImage.gen :data_object => dato, :hierarchy_entry => he
    else
      TopUnpublishedImage.gen :data_object => dato, :hierarchy_entry => he
    end
  elsif type == 'Text'
    DataObjectsTableOfContent.gen(:data_object => dato, :toc_item => bootstrap_toc.rand)
  end
  (rand(60) - 39).times { Comment.gen(:parent => dato, :user => bootstrap_users.rand) }
  return dato
end

def build_taxon_concept(parent, depth, options = {})
  attri = options[:attribution] || Faker::Eol.attribution
  common_name = options[:common_name] || Faker::Eol.common_name
  cform = CanonicalForm.gen(:string => options[:canonical_form] || Faker::Eol.scientific_name)
  sname = Name.gen(:canonical_form => cform, :string => "#{cform.string} #{attri}".strip,
                   :italicized     => "<i>#{cform.string}</i> #{attri}".strip)
  cname = Name.gen(:canonical_form => cform, :string => common_name, :italicized => common_name)
  tc    = TaxonConcept.gen()
  he    = HierarchyEntry.gen(:hierarchy     => Hierarchy.default,
                             :parent_id     => parent,
                             :depth         => depth,
                             :rank_id       => depth + 1, # Cheating. As long as the order is sane, this works well.
                             :taxon_concept => tc,
                             :name          => sname)
  HierarchiesContent.gen(:hierarchy_entry => he, :text => 1, :image => 1, :content_level => 4)
  TaxonConceptName.gen(:preferred => true, :vern => false, :source_hierarchy_entry_id => he.id, :language => Language.english,
                       :name => sname, :taxon_concept => tc)
  TaxonConceptName.gen(:preferred => true, :vern => true, :source_hierarchy_entry_id => he.id, :language => Language.english,
                       :name => cname, :taxon_concept => tc)
  curator = Factory(:curator, :curator_hierarchy_entry => he)
  # TODO - add some alternate names.
  # TODO - do we need to add a relationship between this HE and the agent?  We don't have a HierarchiesResource model yet.
  # TODO - an IUCN entry would be nice.
  # TODO - Creating other TOC items (common names, BHL, synonyms, etc) would be nice 
  # TODO - Movies, GBIF maps

  # Is this the correct name to relate this to?  ...I'm not sure:
  taxon = Taxon.gen(:name => sname, :hierarchy_entry => he, :scientific_name => cform.string)
  images = []
  (rand(12)+3).times do
    images << build_dato('Image', Faker::Lorem.sentence, taxon, he, :object_cache_url => Faker::Eol.image)
  end
  # So, every HE will have each of the following, making testing easier:
  images << build_dato('Image', 'untrusted', taxon, he, :object_cache_url => Faker::Eol.image,
                       :vetted => Vetted.untrusted)
  images << build_dato('Image', 'unknown', taxon, he, :object_cache_url => Faker::Eol.image,
                       :vetted => Vetted.unknown)
  images << build_dato('Image', 'invisible', taxon, he, :object_cache_url => Faker::Eol.image,
                       :visibility => Visibility.invisible)
  images << build_dato('Image', 'invisible, unknown', taxon, he, :object_cache_url => Faker::Eol.image,
                       :visibility => Visibility.invisible, :vetted => Vetted.unknown)
  images << build_dato('Image', 'invisible, untrusted', taxon, he, :object_cache_url => Faker::Eol.image,
                       :visibility => Visibility.invisible, :vetted => Vetted.untrusted)
  images << build_dato('Image', 'preview', taxon, he, :object_cache_url => Faker::Eol.image,
                       :visibility => Visibility.preview)
  images << build_dato('Image', 'preview, unknown', taxon, he, :object_cache_url => Faker::Eol.image,
                       :visibility => Visibility.preview, :vetted => Vetted.unknown)
  images << build_dato('Image', 'inappropriate', taxon, he, :object_cache_url => Faker::Eol.image,
                       :visibility => Visibility.inappropriate)
  
  overview = build_dato('Text', "This is an overview of the <b>#{cform.string}</b> hierarchy entry.", taxon)
  # Add more toc items:
  (rand(4)+1).times do
    dato = build_dato('Text', Faker::Lorem.paragraph, taxon)
  end

  RandomTaxon.gen(:language => Language.english, :data_object => images.last, :name_id => sname.id,
                  :image_url => images.last.object_cache_url, :name => sname.italicized, :content_level => 4, :taxon_concept => tc,
                  :common_name_en => cname.string, :thumb_url => images.first.object_cache_url) # not sure thumb_url is right.
end

# A singleton that creates some users:
def bootstrap_users
  @@bootstrap_users ||= []
  return @@bootstrap_users unless @@bootstrap_users.length == 0
  12.times { @@bootstrap_users << User.gen }
  return @@bootstrap_users
end

# A singleton that creates a 12-item TOC once and only once:
def bootstrap_toc
  @@bootstrap_toc ||= [TocItem.overview]
  return @@bootstrap_toc unless @@bootstrap_toc.length == 1
  toc_len  = 1
  12.times do
    @@bootstrap_toc << TocItem.gen(:parent_id  => (rand(100) > 70) ? @@bootstrap_toc.last.id : 0, :view_order => (toc_len += 1))
  end
  return @@bootstrap_toc
end

# TODO - I am neglecting to set up agent content partners, curators, contacts, provided data types, or agreements.  For now.

%w{phylum order class family genus species subspecies infraspecies variety form}.each do |rank|
  Rank.gen :label => rank
end

resource = Resource.gen(:resource_status => ResourceStatus.published, :accesspoint_url => 'http://google.com')
event = HarvestEvent.gen(:resource => resource)
AgentsResource.gen(:agent => Agent.catalogue_of_life, :resource => resource, :resource_agent_role => ResourceAgentRole.content_partner_upload_role)

kingdom = build_taxon_concept(0, 0, :canonical_form => 'Animalia', :common_name => 'Animals')
6.times do
  build_taxon_concept(Hierarchy.default.hierarchy_entries.last.id, Hierarchy.default.hierarchy_entries.length)
end

include EOL::Data
make_all_nested_sets
# TODO - we need to build TopImages such that ancestors contain the images of their descendants
