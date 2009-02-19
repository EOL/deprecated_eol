# Put a few taxa (all within a new hierarchy) in the database with a range of
# accoutrements.  Depends on foundation scenario!

# This gives us some required methods:
include EOL::Data

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

def build_hierarchy_entry(parent, depth, tc, name, options = {})
  he    = HierarchyEntry.gen(:hierarchy     => options[:hierarchy] || Hierarchy.default,
                             :parent_id     => parent,
                             :depth         => depth,
                             :rank_id       => depth + 1, # Cheating. As long as the order is sane, this works well.
                             :taxon_concept => tc,
                             :name          => name)
  HierarchiesContent.gen(:hierarchy_entry => he, :text => 1, :image => 1, :content_level => 4, :gbif_image => 1, :youtube => 1, :flash => 1)
  return he
end

def build_taxon_concept(parent, depth, options = {})
  attri = options[:attribution] || Faker::Eol.attribution
  common_name = options[:common_name] || Faker::Eol.common_name
  cform = CanonicalForm.gen(:string => options[:canonical_form] || Faker::Eol.scientific_name)
  sname = Name.gen(:canonical_form => cform, :string => "#{cform.string} #{attri}".strip,
                   :italicized     => "<i>#{cform.string}</i> #{attri}".strip)
  cname = Name.gen(:canonical_form => cform, :string => common_name, :italicized => common_name)
  tc    = TaxonConcept.gen(:vetted => Vetted.trusted)
  he    = build_hierarchy_entry(parent, depth, tc, sname)
  TaxonConceptName.gen(:preferred => true, :vern => false, :source_hierarchy_entry_id => he.id, :language => Language.english,
                       :name => sname, :taxon_concept => tc)
  TaxonConceptName.gen(:preferred => true, :vern => true, :source_hierarchy_entry_id => he.id, :language => Language.english,
                       :name => cname, :taxon_concept => tc)
  curator = Factory(:curator, :curator_hierarchy_entry => he)
  (rand(60) - 39).times { Comment.gen(:parent => tc, :parent_type => 'taxon_concept', :user => bootstrap_users.rand) }
  # TODO - add some alternate names.

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
  
  # TODO - Does an IUCN entry *really* need its own taxon?  I am surprised by this (it seems dupicated):
  iucn_taxon = Taxon.gen(:name => sname, :hierarchy_entry => he, :scientific_name => cform.string)
  iucn = build_dato('IUCN', Faker::Eol.iucn, iucn_taxon)
  # TODO - this is a TOTAL hack, but this is currently hard-coded and needs to be fixed:
  HarvestEventsTaxon.gen(:taxon => iucn_taxon, :harvest_event => iucn_harvest_event)

  video   = build_dato('Flash',      Faker::Lorem.sentence,  taxon, nil, :object_cache_url => Faker::Eol.flash)
  youtube = build_dato('YouTube',    Faker::Lorem.paragraph, taxon, nil, :object_cache_url => Faker::Eol.youtube)
  map     = build_dato('GBIF Image', Faker::Lorem.sentence,  taxon, nil, :object_cache_url => Faker::Eol.map)

  overview = build_dato('Text', "This is an overview of the <b>#{cform.string}</b> hierarchy entry.", taxon)
  # Add more toc items:
  (rand(4)+1).times do
    dato = build_dato('Text', Faker::Lorem.paragraph, taxon)
  end
  # TODO - Creating other TOC items (common names, BHL, synonyms, etc) would be nice 

  RandomTaxon.gen(:language => Language.english, :data_object => images.last, :name_id => sname.id,
                  :image_url => images.last.object_cache_url, :name => sname.italicized, :content_level => 4, :taxon_concept => tc,
                  :common_name_en => cname.string, :thumb_url => images.first.object_cache_url) # not sure thumb_url is right.
end

def iucn_harvest_event
  @@iucn_he ||= HarvestEvent.gen(:resource_id => 3)
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

#### Real work begins

# TODO - I am neglecting to set up agent content partners, curators, contacts, provided data types, or agreements.  For now.

%w{phylum order class family genus species subspecies infraspecies variety form}.each do |rank|
  Rank.gen :label => rank
end

# The third resource *must* be IUCN (for now), so I'm going to force the issue:
Resource.delete_all # TODO - truncate  .,...I can't seem to include the right module to allow this, in a rush
HarvestEvent.delete_all(:resource_id => 3)
resource = Resource.gen(:title => 'Bootstrapper', :resource_status => ResourceStatus.published)
bogus    = Resource.gen(:title => 'Filler, ignore', :resource_status => ResourceStatus.published)
iucn_res = Resource.gen(:title => 'IUCN import', :resource_status => ResourceStatus.published)
raise "Something went wrong with creating the iucn resource--it must have an ID of 3, got #{iucn_res.id}" unless iucn_res.id == 3

event    = HarvestEvent.gen(:resource => resource)
AgentsResource.gen(:agent => Agent.catalogue_of_life, :resource => resource,
                   :resource_agent_role => ResourceAgentRole.content_partner_upload_role)
AgentsResource.gen(:agent => Agent.iucn, :resource => iucn_res,
                   :resource_agent_role => ResourceAgentRole.content_partner_upload_role)

kingdom = build_taxon_concept(0, 0, :canonical_form => 'Animalia', :common_name => 'Animals')
6.times do
  build_taxon_concept(Hierarchy.default.hierarchy_entries.last.id, Hierarchy.default.hierarchy_entries.length)
end

# Now that we're done with CoL, we add another content partner who overlaps with them:
tc   = TaxonConcept.find(6) # Whatever.
       # Give it a new name:
name = Name.gen(:canonical_form => tc.canonical_form_object, :string => n = Faker::Eol.scientific_name,
                :italicized     => "<i>#{n}</i> #{Faker::Eol.attribution}")
agent2 = Agent.gen :username => 'test_cp'
cp     = ContentPartner.gen :vetted => true, :agent => agent2
cont   = AgentContact.gen :agent => agent2, :agent_contact_role => AgentContactRole.primary
r2     = Resource.gen(:title => 'Test ContentPartner import', :resource_status => ResourceStatus.processed)
ev2    = HarvestEvent.gen(:resource => r2)
ar     = AgentsResource.gen(:agent => agent2, :resource => r2, :resource_agent_role => ResourceAgentRole.content_partner_upload_role)
hier   = Hierarchy.gen :agent => agent2
he     = build_hierarchy_entry 0, 0, tc, name, :hierarchy => hier
img    = build_dato('Image', "This should only be seen by ContentPartner #{cp.description}", tc.images.first.taxa[0], he,
                  :object_cache_url => Faker::Eol.image, :vetted => Vetted.unknown, :visibility => Visibility.preview)

# generate a default admin user (username,password=admin) and then set them up for the default roles
User.gen :username=>'admin',:hashed_password=>'21232f297a57a5a743894a0e4a801fc3',:email=>'admin@test.com',:given_name=>'Admin',:family_name=>'User',:default_taxonomic_browser=>'text',:expertise=>'middle',:remote_ip=>'127.0.0.1',:content_level=>'2',:flash_enabled=>'1',:vetted=>'0',:mailing_list=>'0',:active=>'1',:language_id=>'1'
admin=User.find_by_username('admin')
admin.roles << Role.find_by_title('Administrator')
admin.roles << Role.find_by_title('Administrator - Web Users')
admin.roles << Role.find_by_title('Administrator - News Items')
admin.roles << Role.find_by_title('Administrator - Comments and Tags')
admin.roles << Role.find_by_title('Administrator - Contact Us Submissions')
admin.roles << Role.find_by_title('Administrator - Content Partners')
admin.roles << Role.find_by_title('Administrator - Error Logs')
admin.roles << Role.find_by_title('Administrator - Site CMS')
admin.roles << Role.find_by_title('Administrator - Usage Reports')
                  
make_all_nested_sets
# TODO - we need to build TopImages such that ancestors contain the images of their descendants
