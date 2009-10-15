# Put a few taxa (all within a new hierarchy) in the database with a range of accoutrements
#
#   TODO add a description here of what actually gets created!
#
#   This description block can be viewed (as well as other information 
#   about this scenario) by running:
#     $ rake scenarios:show NAME=bootstrap
#
# ---
# dependencies: [ :foundation ]
# arbitrary_variable: arbitrary value
require 'spec/scenario_helpers'

# A singleton that creates some users:
def bootstrap_users
  @@bootstrap_users ||= []
  return @@bootstrap_users unless @@bootstrap_users.length == 0
  12.times { @@bootstrap_users << User.gen }
  return @@bootstrap_users
end

# This used to be... random.  Now, I'm creating a small subset of the "real" TocItems.
def bootstrap_toc
  current_order = TocItem.count # Just a reasonable place to start counting for "parent" items.
  description_labels = [
      'Succinct',
      'Diagnosis of genus and species',
      'Physical Description',
      'Formal Description',
      'Molecular Biology and Genetics',
      'Phenology',
      'Life History',
      'Geographical Distribution',
      'Etymology',
      'Adult Characteristics',
      'Comparison with Similar Species',
      'Host, Oviposition, and Larval Feeding Habits',
      'Type',
      'Characteristics',
      'General Description'
  ]
  make_toc_children(TocItem.find_by_label('Description').id, description_labels)
  TocItem.gen(:label => 'Reproductive Behavior', :parent_id => 0, :view_order => current_order += 1)
  TocItem.gen(:label => 'Conservation', :parent_id => 0, :view_order => current_order += 1)
  TocItem.gen(:label => 'Evolution and Systematics', :parent_id => 0, :view_order => current_order += 1)
  TocItem.gen(:label => 'Literature References', :parent_id => 0, :view_order => current_order += 1)
  relevance = TocItem.gen(:label => 'Relevance', :parent_id => 0, :view_order => current_order += 1)
  relevance_labels = [
    'Harmful Blooms',
    'Relation to Humans',
    'Toxicity, Symptoms and Treatment',
    'Cultivation',
    'Culture',
    'Ethnobotany',
    'Suppliers'
  ]
  make_toc_children(relevance.id, relevance_labels)
end

def make_toc_children(parent_id, labels)
  current_order = 0
  labels.each do |label|
    current_order += 1
    TocItem.gen(:label => label, :parent_id => parent_id, :view_order => current_order)
  end
end


#### Real work begins

bootstrap_toc

Rails.cache.clear # We appear to be altering some of the cached classes here.  JRice 6/26/09

# TODO - I am neglecting to set up agent content partners, curators, contacts, provided data types, or agreements.  For now.

resource = Resource.gen(:title => 'Bootstrapper', :resource_status => ResourceStatus.published)
event    = HarvestEvent.gen(:resource => resource)
AgentsResource.gen(:agent => Agent.catalogue_of_life, :resource => resource,
                   :resource_agent_role => ResourceAgentRole.content_partner_upload_role)

gbif_agent = Agent.gen(:full_name => "Global Biodiversity Information Facility (GBIF)")
#gbif_agent = Agent.find_by_full_name('Global Biodiversity Information Facility (GBIF)');
gbif_cp    = ContentPartner.gen :vetted => true, :agent => gbif_agent
AgentContact.gen(:agent => gbif_agent, :agent_contact_role => AgentContactRole.primary)
gbif_hierarchy = Hierarchy.gen(:agent => gbif_agent, :label => "GBIF Nub Taxonomy")

kingdom = build_taxon_concept(:rank => 'kingdom', :canonical_form => 'Animalia', :event => event)
kingdom.add_common_name('Animals')

4.times do
  tc = build_taxon_concept(:parent_hierarchy_entry_id => Hierarchy.default.hierarchy_entries.last.id,
                           :depth => Hierarchy.default.hierarchy_entries.length,
                           :event => event)
  tc.add_common_name(Factory.next(:common_name))
end

fifth_entry_id = Hierarchy.default.hierarchy_entries.last.id
depth_now      = Hierarchy.default.hierarchy_entries.length

# NOTE!  I am going to use HARDCODED common names *JUST* so that searching will have multiple results for one string.

# Sixth Taxon should have more images, and have videos:
tc = build_taxon_concept(:parent_hierarchy_entry_id => fifth_entry_id,
                         :depth => depth_now, :images => :testing, :event => event)
tc.add_common_name('Tiger moth')

#TODO: omg this is HORRIBLE!
u = User.gen
u.vetted = false
tc.current_user = u
tc.images.first.comments[0].body = 'First comment'
tc.images.first.comments[0].save!
tc.images.first.comment(u, 'Second comment')
tc.images.first.comment(u, 'Third comment')
tc.images.first.comment(u, 'Forth comment')
tc.images.first.comment(u, 'Fifth comment')
tc.images.first.comment(u, 'Sixth comment')
tc.images.first.comment(u, 'Seventh comment')
tc.images.first.comment(u, 'Eighth comment')
tc.images.first.comment(u, 'Nineth comment')
tc.images.first.comment(u, 'Tenth comment')
tc.images.first.comment(u, 'Eleventh comment')
tc.images.first.comment(u, 'Twelveth comment')

# Seventh Taxon (sign of the apocolypse?) should be a child of fifth and be "empty", other than common names:
tc = build_taxon_concept(:parent_hierarchy_entry_id => fifth_entry_id,
                         :depth => depth_now, :images => [], :toc => [], :flash => [], :youtube => [], :comments => [],
                         :bhl => [], :event => event)
tc.add_common_name('Tiger lilly')

# Eighth Taxon (now we're just getting greedy) should be the same as Seven, but with BHL:
tc = build_taxon_concept(:parent_hierarchy_entry_id => fifth_entry_id,
                         :depth => depth_now, :images => [], :toc => [], :flash => [], :youtube => [], :comments => [],
                         :event => event)
tc.add_common_name('Tiger')

# Ninth Taxon is *totally* naked:
build_taxon_concept(:parent_hierarchy_entry_id => fifth_entry_id, :common_names => [], :bhl => [], :event => event,
                    :depth => depth_now, :images => [], :toc => [], :flash => [], :youtube => [], :comments => [])

#30 has unvetted images and videos, please don't change this one, needed for selenum tests:         
tc30 = build_taxon_concept(:id => 30, :parent_hierarchy_entry_id => fifth_entry_id,
                    :depth => depth_now, :images => :testing, :flash => [{:vetted => Vetted.untrusted}], :youtube => [{:vetted => Vetted.untrusted}], :comments => [],
                    :bhl => [], :event => event)
tc30.add_common_name(Factory.next(:common_name))

#(:username => 'curator_for_tc', :password => 'password')
curator_for_tc30 = create_curator(tc30) 

# 1) create comments on text (and the same for image)
#   1a) one is visible, second with visible_at = NULL
text_dato = tc30.overview.last # TODO - this doesn't seem to ACTAULLY be the overview.  Fix it?
image_dato = tc30.images.last
# 2) rating of old version of dato was 1
text_dato.rate(curator_for_tc30, 1)
image_dato.rate(curator_for_tc30, 1)
# 3) create new dato with the same guid and comments on new version
add_comments_and_tags_to_reharvested_data_objects(tc30)

#31 has unvetted and vetted videos, please don't change this one, needed for selenum test:         
build_taxon_concept(:parent_hierarchy_entry_id => fifth_entry_id, :common_names => [Factory.next(:common_name)], :id => 31, 
                    :depth => depth_now, :flash => [{}, {:vetted => Vetted.unknown}], :youtube => [{:vetted => Vetted.unknown}, {:vetted => Vetted.untrusted}], :comments => [],
                    :bhl => [], :event => event)
                    
#32
user = User.gen
overv = TocItem.find_by_label('Overview')
desc = TocItem.find_by_label('Description')
tc = build_taxon_concept(:id => 32, :toc => [{:toc_item => overv}, {:toc_item => overv}, {:toc_item => desc}], :comments => [{}])
description_dato = tc.content_by_category(desc)[:data_objects].first
description_dato.comment(user, 'First comment')
description_dato.comment(user, 'Second comment')  
description_dato.comment(user, 'Third comment')
description_dato.comment(user, 'Forth comment')
description_dato.comment(user, 'Fifth comment')
description_dato.comment(user, 'Sixth comment')
description_dato.comment(user, 'Seventh comment')
description_dato.comment(user, 'Eighth comment')
description_dato.comment(user, 'Ninth comment')
description_dato.comment(user, 'Tenth comment')
description_dato.comment(user, 'Eleventh comment')
description_dato.comment(user, 'Twelfth comment')

DataObjectsInfoItem.gen(:data_object => tc.overview.first, :info_item => InfoItem.find(:first, :order => 'rand()'))
DataObjectsInfoItem.gen(:data_object => tc.overview.last, :info_item => InfoItem.find_by_label("Distribution"))

# Now that we're done with CoL, we add another content partner who overlaps with them:
       # Give it a new name:
name   = Name.gen(:canonical_form => tc.canonical_form_object, :string => n = Factory.next(:scientific_name),
                  :italicized     => "<i>#{n}</i> #{Factory.next(:attribution)}")
agent2 = Agent.gen :username => 'test_cp'
cp     = ContentPartner.gen :vetted => true, :agent => agent2
cont   = AgentContact.gen :agent => agent2, :agent_contact_role => AgentContactRole.primary
r2     = Resource.gen(:title => 'Test ContentPartner import', :resource_status => ResourceStatus.processed)
ev2    = HarvestEvent.gen(:resource => r2)
ar     = AgentsResource.gen(:agent => agent2, :resource => r2, :resource_agent_role => ResourceAgentRole.content_partner_upload_role)
hier   = Hierarchy.gen :agent => agent2
he     = build_hierarchy_entry 0, tc, name, :hierarchy => hier
img    = build_data_object('Image', "This should only be seen by ContentPartner #{cp.description}",
                           :taxon => tc.images.first.taxa[0],
                           :hierarchy_entry => he,
                           :object_cache_url => Factory.next(:image),
                           :vetted => Vetted.unknown,
                           :visibility => Visibility.preview)

# Some node in the GBIF Hierarchy to test maps on
build_hierarchy_entry 0, tc, name, :hierarchy => gbif_hierarchy, :identifier => '13810203'

# Generate a default admin user and then set them up for the default roles:
admin = User.gen :username => 'admin', :password => 'admin', :given_name => 'Admin', :family_name => 'User'
admin.roles = Role.find(:all, :conditions => 'title LIKE "Administrator%"')
admin.save

#user for selenium tests
test_user2 = User.gen(:username => 'test_user2', :password => 'password', :given_name => 'test', :family_name => 'user2')
test_user2.save

#curator for selenium tests (NB: page #30)
curator = User.gen(:username => 'test_curator', :password => 'password', 'given_name' => 'test', :family_name => 'curator', :curator_hierarchy_entry_id => 20, :curator_approved => true)
curator.save

#moderator for selenium test
moderator = User.gen :username => 'moderator', :password => 'moderator', :given_name => 'Moderator', :family_name => 'User'
moderator.roles = Role.find(:all, :conditions => 'title LIKE "Moderator"')
moderator.save

exemplar = build_taxon_concept(:id => 910093, # That ID is one of the (hard-coded) exemplars.
                               :event => event,
                               :common_names => ['wumpus'],
                               :biomedical_terms => true) # LigerCat powers, ACTIVATE!

# Adds a ContentPage at the following URL: http://localhost:3000/content/page/curator_central

ContentPage.gen(:page_name => "curator_central", :title => "Curator central", :left_content => "")



col_collection = Collection.gen(:agent => Agent.catalogue_of_life, :title => "Catalogue of Life Collection", :uri => "http://www.catalogueoflife.org/browse_taxa.php?selected_taxon=FOREIGNKEY", :logo_cache_url => 4130)
col_mapping    = Mapping.gen(:collection => col_collection, :name => kingdom.entry.name_object)



# TODO - we need to build TopImages such that ancestors contain the images of their descendants

# creating collection / mapping data
image_collection_type = CollectionType.gen(:label => "Images")
specimen_image_collection_type = CollectionType.gen(:label => "Specimen", :parent_id => image_collection_type.id)
natural_image_collection_type = CollectionType.gen(:label => "Natural", :parent_id => image_collection_type.id)

species_pages_collection_type = CollectionType.gen(:label => "Species Pages")
molecular_species_pages_collection_type = CollectionType.gen(:label => "Molecular", :parent_id => species_pages_collection_type.id)
novice_pages_collection_type = CollectionType.gen(:label => "Novice", :parent_id => species_pages_collection_type.id)
expert_pages_collection_type = CollectionType.gen(:label => "Expert", :parent_id => species_pages_collection_type.id)

marine_theme_collection_type = CollectionType.gen(:label => "Marine")
bugs_theme_collection_type = CollectionType.gen(:label => "Bugs")

name = kingdom.entry.name_object

specimen_image_collection = Collection.gen(:title => 'AntWeb', :description => 'Currently AntWeb contains information on the ant faunas of several areas in the Nearctic and Malagasy biogeographic regions, and global coverage of all ant genera.', :uri => 'http://www.antweb.org/specimen.do?name=FOREIGNKEY', :link => 'http://www.antweb.org/', :logo_cache_url => '7810')
CollectionTypesCollection.gen(:collection => specimen_image_collection, :collection_type => specimen_image_collection_type)
CollectionTypesCollection.gen(:collection => specimen_image_collection, :collection_type => expert_pages_collection_type)
CollectionTypesCollection.gen(:collection => specimen_image_collection, :collection_type => bugs_theme_collection_type)
Mapping.gen(:collection => specimen_image_collection, :name => name, :foreign_key => 'casent0129891')
Mapping.gen(:collection => specimen_image_collection, :name => name, :foreign_key => 'casent0496198')
Mapping.gen(:collection => specimen_image_collection, :name => name, :foreign_key => 'casent0179524')

molecular_species_pages_collection = Collection.gen(
  :title => 'National Center for Biotechnology Information',
  :description => 'Established in 1988 as a national resource for molecular biology information, NCBI creates public databases, conducts research in computational biology, develops software tools for analyzing genome data, and disseminates biomedical information - all for the better understanding of molecular processes affecting human health and disease',
  :uri => 'http://www.ncbi.nlm.nih.gov/sites/entrez?Db=genomeprj&cmd=ShowDetailView&TermToSearch=FOREIGNKEY',
  :link => 'http://www.ncbi.nlm.nih.gov/',
  :logo_cache_url => '1305')
CollectionTypesCollection.gen(:collection => molecular_species_pages_collection, :collection_type => molecular_species_pages_collection_type)
CollectionTypesCollection.gen(:collection => molecular_species_pages_collection, :collection_type => marine_theme_collection_type)
Mapping.gen(:collection => molecular_species_pages_collection, :name => name, :foreign_key => '13646')
Mapping.gen(:collection => molecular_species_pages_collection, :name => name, :foreign_key => '9551')

r = Rank.gen(:label => 'superkingdom', :rank_group_id => 0)

### Adding another hierarchy to test switching from one to another
ncbi_agent = Agent.gen(:full_name => "National Center for Biotechnology Information (NCBI)", :logo_cache_url => nil)
AgentContact.gen(:agent => ncbi_agent, :agent_contact_role => AgentContactRole.primary)
ncbi_hierarchy = Hierarchy.gen(:agent => ncbi_agent, :label => "NCBI Taxonomy", :browsable => 1)

eukaryota = build_taxon_concept(:rank => 'superkingdom',
                                :canonical_form => 'Eukaryota',
                                :common_names => ['eukaryotes'],
                                :event => event,
                                :hierarchy => ncbi_hierarchy,
                                :depth => 0)

opisthokonts_name   = Name.gen(:canonical_form => cf = CanonicalForm.gen(:string => 'Metazoa'),
                  :string => 'Metazoa',
                  :italicized => '<i>Metazoa</i>')
opisthokonts_common_name   = Name.gen(:canonical_form => cf = CanonicalForm.gen(:string => 'opisthokonts'),
                  :string => 'opisthokonts',
                  :italicized => '<i>opisthokonts</i>')
opisthokonts = build_hierarchy_entry(0, kingdom, opisthokonts_name,
            :rank_id => Rank.find_by_label('kingdom').id,
            :parent_id => ncbi_hierarchy.hierarchy_entries.last.id,
            :hierarchy => ncbi_hierarchy )
TaxonConceptName.gen(:preferred => true, :vern => true, :source_hierarchy_entry_id => opisthokonts.id,
                     :language => Language.english, :name => opisthokonts_common_name, :taxon_concept => kingdom)
TaxonConceptName.gen(:preferred => true, :vern => false, :source_hierarchy_entry_id => opisthokonts.id,
                     :language => Language.scientific, :name => opisthokonts_name, :taxon_concept => kingdom)

4.times do
  parent_id = ncbi_hierarchy.hierarchy_entries.last.id
  depth = ncbi_hierarchy.hierarchy_entries.last.depth + 1
  
  2.times do
    sci_name = Factory.next(:scientific_name)
    c_name = Factory.next(:common_name)
    build_taxon_concept(:rank => '',
                        :canonical_form => sci_name,
                        :common_names => [c_name],
                        :event => event,
                        :hierarchy => ncbi_hierarchy,
                        :parent_hierarchy_entry_id => parent_id,
                        :depth => depth)
  end

end


bacteria = build_taxon_concept(:rank => 'superkingdom',
                                :canonical_form => 'Bacteria',
                                :event => event,
                                :hierarchy => ncbi_hierarchy,
                                :depth => 0)

# We need to be able to test changing the preferred name across several languages:
english = Language.english
bacteria.add_common_name("bacteria", :language => english, :preferred => true)
bacteria.add_common_name("bugs", :language => english, :preferred => false)
bacteria.add_common_name("grime", :language => english, :preferred => false)
bacteria.add_common_name("critters", :language => english, :preferred => false)
german  = Language.gen(:label => 'German', :iso_639_1 => 'de')
bacteria.add_common_name("bakteria", :language => german, :preferred => true)
bacteria.add_common_name("die buggen", :language => german, :preferred => false)
bacteria.add_common_name("das greim", :language => german, :preferred => false)
french = Language.find_by_label('French') # Assumes French was defined in foundation
bacteria.add_common_name("baseteir", :language => french, :preferred => true)
bacteria.add_common_name("le grimme", :language => french, :preferred => false)
bacteria.add_common_name("ler petit bugge", :language => french, :preferred => false)

# Another Selenium curator
curator2 = User.gen(:username => 'curator_two', :password => 'iliketocurate')
curator2.approve_to_curate! bacteria.entry

4.times do
  parent_id = ncbi_hierarchy.hierarchy_entries.last.id
  depth = ncbi_hierarchy.hierarchy_entries.last.depth + 1
  
  sci_name = Factory.next(:scientific_name)
  c_name = Factory.next(:common_name)
  build_taxon_concept(:rank => '',
                      :canonical_form => sci_name,
                      :common_names => [c_name],
                      :event => event,
                      :hierarchy => ncbi_hierarchy,
                      :parent_hierarchy_entry_id => parent_id,
                      :depth => depth)
end







TaxonConcept.all.each do |tc|
  if tc.hierarchy_entries.empty?
    TaxonConcept.delete(tc.id)
  end
end

RandomHierarchyImage.all.each do |rhi|
  d = DataObject.find(rhi.data_object_id)
  Comment.find_all_by_parent_type_and_parent_id('DataObject',d.id).each do |c|
    c.destroy
  end
  d.destroy
  rhi.destroy
end
HierarchyEntry.all.each do |he|
  RandomHierarchyImage.gen(:hierarchy => he.hierarchy, :taxon_concept => he.taxon_concept, :hierarchy_entry => he, :data_object => he.taxon_concept.images[0]) if !he.taxon_concept.images[0].nil?
end

make_all_nested_sets
recreate_normalized_names_and_links
rebuild_collection_type_nested_set

DataObject.find(:all).each_with_index do |d,i|
  d.created_at = Time.now - i.hours
  d.save!
end

Comment.find(:all).each_with_index do |c,i|
  c.created_at = Time.now - i.hours
  c.save!
end
