# Put a few taxa (all within a new hierarchy) in the database with a range of
# accoutrements.  Depends on foundation scenario!

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
    TopImage.gen :data_object => dato, :hierarchy_entry => he
  end
  # TODO - I am not setting the mime type yet.  We never use it.
  # TODO - There are no models for all the refs_* tables, so I'm ignoring them.
  # TODO - we have no synonyms.
  return dato
end


# I am neglecting to set up agent content partners, contacts, provided data types, or agreements.  For now.
overview = TocItem.gen(:label => 'Overview')
toc      = [overview]
toc_len  = 1
12.times do
  toc << TocItem.gen(:parent_id  => (rand(100) > 70) ? toc.last.id : 0,
                     :view_order => (toc_len += 1))
end

agent     = Agent.gen(:agent_status => AgentStatus.active) # See?  We *already* need foundation.
# We *depend* on CoL, currently, so this is required:
hierarchy = Hierarchy.gen(:agent => agent, :label => "Species 2000 & ITIS Catalogue of Life: Annual Checklist 2008")
animals_cform = CanonicalForm.gen(:string => 'Animalia')
animals_sname = Name.gen(:canonical_form => animals_cform, :string => 'Animalia', :italicized => "<i>Animalia</i>")
animals_cname = Name.gen(:canonical_form => animals_cform, :string => 'Animals',  :italicized => 'Animals')
animals_tc    = TaxonConcept.gen()
kingdom       = HierarchyEntry.gen(:hierarchy => hierarchy, :depth => 0, :name => animals_sname, :taxon_concept => animals_tc)
TaxonConceptName.gen(:preferred => true, :vern => false, :source_hierarchy_entry_id => kingdom.id, :language => Language.english,
                     :name => animals_sname, :taxon_concept => animals_tc)
TaxonConceptName.gen(:preferred => true, :vern => true, :source_hierarchy_entry_id => kingdom.id, :language => Language.english,
                     :name => animals_cname, :taxon_concept => animals_tc)
# TODO - I *tried* to use should_receive to fake that URL such that it doesn't need to check it, but that was FAIL.
# For some reason, even if you require 'rspec/expecations', it still can't find should_receive on the class.
resource  = Resource.gen(:resource_status => ResourceStatus.published, :accesspoint_url => 'http://google.com')
event     = HarvestEvent.gen(:resource => resource)

AgentsResource.gen(:agent => agent, :resource => resource, :resource_agent_role => ResourceAgentRole.content_partner_upload_role)

6.times do
  attri = Faker::Eol.attribution
  cform = CanonicalForm.gen(:string => Faker::Eol.scientific_name)
  sname = Name.gen(:canonical_form => cform, :string => "#{cform.string} #{attri}", :italicized => "<i>#{cform.string}</i> #{attri}")
  cname = Name.gen(:canonical_form => cform, :string => rn = Faker::Eol.common_name, :italicized => rn)
  tc    = TaxonConcept.gen()
  he    = HierarchyEntry.gen(:hierarchy     => hierarchy,
                             :parent_id     => hierarchy.hierarchy_entries.last,
                             :depth         => hierarchy.hierarchy_entries.length,
                             :taxon_concept => tc,
                             :name          => sname)
  TaxonConceptName.gen(:preferred => true, :vern => false, :source_hierarchy_entry_id => he.id, :language => Language.english,
                       :name => sname, :taxon_concept => tc)
  TaxonConceptName.gen(:preferred => true, :vern => true, :source_hierarchy_entry_id => he.id, :language => Language.english,
                       :name => cname, :taxon_concept => tc)
  # TODO - add some alternate names.
  # TODO - do we need to add a relationship between this HE and the agent?  We don't have a HierarchiesResource model yet.
  # TODO - an IUCN entry would be nice.
  # TODO - Creating other TOC items (common names, BHL, etc) would be nice
  # TODO - Movies, GBIF maps

  # Is this the correct name to relate this to?  ...I'm not sure:
  taxon = Taxon.gen(:name => sname, :hierarchy_entry => he, :scientific_name => cform.string)
  images = []
  (rand(12)+3).times do
    images << build_dato('Image', Faker::Lorem.sentence, taxon, he, :object_cache_url => Faker::Eol.image)
  end
  
  overview_dato = build_dato('Text', "This is an overview of the <b>#{cform.string}</b> hierarchy entry.", taxon)
  DataObjectsTableOfContent.gen(:data_object => overview_dato, :toc_item => overview)
  # Add more toc items:
  (rand(4)+1).times do
    dato = build_dato('Text', Faker::Lorem.paragraph, taxon)
    DataObjectsTableOfContent.gen(:data_object => dato, :toc_item => toc.rand)
  end

  RandomTaxon.gen(:language => Language.english, :data_object => images.last, :name_id => sname.id,
                  :image_url => images.last.object_cache_url, :name => sname.italicized, :content_level => 4, :taxon_concept => tc,
                  :common_name_en => cname.string, :thumb_url => images.first.object_cache_url) # not sure thumb_url is right.
end
# TODO - we need to rebuild the lft, rgt, and ancestry values on all of those HEs.
