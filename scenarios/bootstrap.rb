# Put a few taxa (all within a new hierarchy) in the database with a range of
# accoutrements.  Depends on foundation scenario!

def build_dato(type, desc, taxon, options = {})
    attributes = {:data_type   => DataType.find_by_label(type),
                  :description => desc,
                  :visibility  => Visibility.visible,
                  :vetted      => Vetted.trusted,
                  # Yes, rand on all licenses is inefficient.  Lazy.  TODO ?
                  :license     => License.all.rand}
  dato = DataObject.gen(attributes.merge(options))
  DataObjectsTaxon.gen(:data_object => dato, :taxon => taxon)
  # TODO - I am not setting the mime type yet.  We never use it.
  # TODO - There are no models for all the refs_* tables, so I'm ignoring them.
  # TODO - we have no synonyms.
  return dato
end

def rand_image
  %w{
    200810061400963 200812102286938 200901131511113 200810061535996 200810061235832 200810070724291 200810070393325 200810061499033
    200810061956645 200901081611403 200902021821277 200901081525790 200810070370443 200810081234383 200901091228271 200810061332994
  }.rand
end

def rand_name_part
 part = Faker::Lorem.words(1)[0]
 part += Faker::Lorem.words(1)[0] if part.length < 4
 part += %w{i a ii us is iae erox eron eri alia eli esi alia elia ens ica ator atus erus ensis alis alius osyne eles es ata}.rand
end

def rand_scientific_name
  "#{rand_name_part} #{rand_name_part}"
end

def rand_common_name
  ['common', "#{Faker::Name.first_name}'s", 'blue', 'red', 'pink', 'green', 'purple',
   'painted', 'spiny', 'agitated', 'horny', 'blessed', 'sacred', 'sacrimonious', 'naughty',
   'litte', 'tiny', 'giant', 'great', 'lesser', 'least', 'river', 'plains', 'city', 'sky', 'stream',
   'thirsty', 'ravenous', 'bloody', 'cursed', 'cromulent'].rand + ' ' + rand_name_part
end

def rand_attribution
  "#{Faker::Name.first_name[0..0]}. #{Faker::Name.last_name}"
end

# I am neglecting to set up agent content partners, contacts, provided data types, or agreements.  For now.
overview = TocItem.gen(:label => 'Overview')
toc      = [overview]
toc_len  = 1
12.times do
  TocItem.gen(:parent_id  => (rand(100) > 70) ? toc.last.id : 0,
              :view_order => (toc_len += 1))
end

agent     = Agent.gen(:agent_status => AgentStatus.active) # See?  We *already* need foundation.
hierarchy = Hierarchy.gen(:agent => agent)
kingdom   = HierarchyEntry.gen(:hierarchy => hierarchy, :depth => 0)
# TODO - I *tried* to use should_receive to fake that URL such that it doesn't need to check it, but that was FAIL.
# For some reason, even if you require 'rspec/expecations', it still can't find should_receive on the class.
resource  = Resource.gen(:resource_status => ResourceStatus.published, :accesspoint_url => 'http://google.com')
event     = HarvestEvent.gen(:resource => resource)

AgentsResource.gen(:agent => agent, :resource => resource, :resource_agent_role => ResourceAgentRole.content_partner_upload_role)

6.times do
  attri = rand_attribution
  cform = CanonicalForm.gen(:string => rand_scientific_name)
  sname = Name.gen(:canonical_form => cform, :string => "#{cform.string} #{attri}", :italicized => "<i>#{cform.string}</i> #{attri}")
  cname = Name.gen(:canonical_form => cform, :string => rn = rand_common_name, :italicized => rn)
  tc    = TaxonConcept.gen()
  he    = HierarchyEntry.gen(:hierarchy     => hierarchy,
                             :parent_id     => hierarchy.hierarchy_entries.last,
                             :depth         => hierarchy.hierarchy_entries.length,
                             :taxon_concept => tc)
  TaxonConceptName.gen(:preferred => true, :vern => false, :source_hierarchy_entry_id => he.id, :language => Language.english,
                       :name => sname, :taxon_concept => tc)
  TaxonConceptName.gen(:preferred => true, :vern => true, :source_hierarchy_entry_id => he.id, :language => Language.english,
                       :name => cname, :taxon_concept => tc)
  # TODO - add some alternate names.
  # TODO - do we need to add a relationship between this HE and the agent?  We don't have a HierarchiesResource model yet.

  # Is this the correct name to relate this to?  ...I'm not sure:
  taxon = Taxon.gen(:name => sname, :hierarchy_entry => he, :scientific_name => cform.string)
  images = []
  (rand(12)+1).times do
    images << build_dato('Image', Faker::Lorem.sentence, taxon, :object_cache_url => rand_image)
  end
  
  overview_dato = build_dato('Text', "This is an overview of the <b>#{cform.string}</b> hierarchy entry.", taxon)
  DataObjectsTableOfContent.gen(:data_object => overview_dato, :toc_item => overview)
  # Add more toc items:
  (rand(4)+1).times do
    dato = build_dato('Text', Faker::Lorem.paragraph, taxon)
    DataObjectsTableOfContent.gen(:data_object => dato, :toc_item => toc.rand)
  end

  RandomTaxon.gen(:language => Language.english, :data_object => images.last, :name_id => sname.id,
                  :image_url => images.last.object_cache_url, :name => sname.italicized, rt.content_level => 4, :taxon_concept => tc)
end
# TODO - we need to rebuild the lft, rgt, and ancestry values on all of those HEs.
