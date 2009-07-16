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

require 'spec/eol_spec_helpers'
# This gives us the ability to recalculate some DB values:
include EOL::Data
# This gives us the ability to build taxon concepts:
include EOL::Spec::Helpers

# A singleton that creates some users:
def bootstrap_users
  @@bootstrap_users ||= []
  return @@bootstrap_users unless @@bootstrap_users.length == 0
  12.times { @@bootstrap_users << User.gen }
  return @@bootstrap_users
end

# A singleton that creates a 12-item TOC once and only once:
def bootstrap_toc
  @@bootstrap_toc ||= [TocItem.overview, TocItem.description]
  return @@bootstrap_toc unless @@bootstrap_toc.length == 1
  toc_len  = 1
  12.times do
    @@bootstrap_toc << TocItem.gen(:parent_id  => (rand(100) > 70) ? @@bootstrap_toc.last.id : 0, :view_order => (toc_len += 1))
  end
  return @@bootstrap_toc
end

#### Real work begins

Rails.cache.clear # We appear to be altering some of the cached classes here.  JRice 6/26/09

# Before we create our new taxa, we should make sure the RandomTaxa table is clear of bogus entries:
RandomTaxon.all.each do |rt|
  RandomTaxon.delete("id = #{rt.id}") if (TaxonConcept.find(rt.taxon_concept_id)).nil?
end

# Before we create our new taxa, we should make sure the RandomTaxa table is clear of bogus entries:
RandomHierarchyImage.all.each do |rhi|
  RandomHierarchyImage.delete("id = #{rhi.id}") if (TaxonConcept.find(rhi.taxon_concept_id)).nil?
end

# TODO - I am neglecting to set up agent content partners, curators, contacts, provided data types, or agreements.  For now.

resource = Resource.gen(:title => 'Bootstrapper', :resource_status => ResourceStatus.published)
event    = HarvestEvent.gen(:resource => resource)
AgentsResource.gen(:agent => Agent.catalogue_of_life, :resource => resource,
                   :resource_agent_role => ResourceAgentRole.content_partner_upload_role)

gbif_agent = Agent.gen(:full_name => "Global Biodiversity Information Facility (GBIF)")
#gbif_agent = Agent.find_by_full_name('Global Biodiversity Information Facility (GBIF)');
AgentContact.gen(:agent => gbif_agent, :agent_contact_role => AgentContactRole.primary)
gbif_hierarchy = Hierarchy.gen(:agent => gbif_agent, :label => "GBIF Nub Taxonomy")

kingdom = build_taxon_concept(:rank => 'kingdom', :canonical_form => 'Animalia', :common_names => ['Animals'],
                              :event => event)
4.times do
  build_taxon_concept(:parent_hierarchy_entry_id => Hierarchy.default.hierarchy_entries.last.id,
                      :depth => Hierarchy.default.hierarchy_entries.length,
                      :event => event,
                      :common_names => [Factory.next(:common_name)])
end

fifth_entry_id = Hierarchy.default.hierarchy_entries.last.id
depth_now      = Hierarchy.default.hierarchy_entries.length

# Sixth Taxon should have more images, and have videos:
tc = build_taxon_concept(:parent_hierarchy_entry_id => fifth_entry_id, :common_names => [Factory.next(:common_name)],
                         :depth => depth_now, :images => :testing, :event => event)

# Seventh Taxon (sign of the apocolypse?) should be a child of fifth and be "empty", other than common names:
build_taxon_concept(:parent_hierarchy_entry_id => fifth_entry_id, :common_names => [Factory.next(:common_name)],
                    :depth => depth_now, :images => [], :toc => [], :flash => [], :youtube => [], :comments => [],
                    :bhl => [], :event => event)

# Eighth Taxon (now we're just getting greedy) should be the same as Seven, but with BHL:
build_taxon_concept(:parent_hierarchy_entry_id => fifth_entry_id, :common_names => [Factory.next(:common_name)],
                    :depth => depth_now, :images => [], :toc => [], :flash => [], :youtube => [], :comments => [],
                    :event => event)

# Ninth Taxon is *totally* naked:
build_taxon_concept(:parent_hierarchy_entry_id => fifth_entry_id, :common_names => [], :bhl => [], :event => event,
                    :depth => depth_now, :images => [], :toc => [], :flash => [], :youtube => [], :comments => [])

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

#curator for selenium tests (NB: page #11, Animalia)
curator = User.gen(:username => 'test_curator', :password => 'password', 'given_name' => 'test', :family_name => 'curator', :curator_hierarchy_entry_id => 4, :curator_approved => true)
curator.save


exemplar = build_taxon_concept(:event => event, :common_names => ['wumpus'], :id => 910093) # That ID is one of the (hard-coded) exemplars.

# Adds a ContentPage at the following URL: http://localhost:3000/content/page/curator_central

ContentPage.gen(:page_name => "curator_central", :title => "Curator central", :left_content => "")

# TODO - we need to build TopImages such that ancestors contain the images of their descendants





r = Rank.gen(:label => 'superkingdom', :rank_group_id => 0)

### Adding another hierarchy to test switching from one to another
ncbi_agent = Agent.gen(:full_name => "National Center for Biotechnology Information (NCBI)")
AgentContact.gen(:agent => ncbi_agent, :agent_contact_role => AgentContactRole.primary)
ncbi_hierarchy = Hierarchy.gen(:agent => ncbi_agent, :label => "NCBI Taxonomy")

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
  
  sci_name = Factory.next(:scientific_name)
  c_name = Factory.next(:common_name)
  eukaryota = build_taxon_concept(:rank => '',
                                  :canonical_form => sci_name,
                                  :common_names => [c_name],
                                  :event => event,
                                  :hierarchy => ncbi_hierarchy,
                                  :parent_hierarchy_entry_id => parent_id,
                                  :depth => depth)
  
  sci_name = Factory.next(:scientific_name)
  c_name = Factory.next(:common_name)
  eukaryota = build_taxon_concept(:rank => '',
                                  :canonical_form => sci_name,
                                  :common_names => [c_name],
                                  :event => event,
                                  :hierarchy => ncbi_hierarchy,
                                  :parent_hierarchy_entry_id => parent_id,
                                  :depth => depth)
end


bacteria = build_taxon_concept(:rank => 'superkingdom',
                                :canonical_form => 'Bacteria',
                                :common_names => ['bacteria common name'],
                                :event => event,
                                :hierarchy => ncbi_hierarchy,
                                :depth => 0)

4.times do
  parent_id = ncbi_hierarchy.hierarchy_entries.last.id
  depth = ncbi_hierarchy.hierarchy_entries.last.depth + 1
  
  sci_name = Factory.next(:scientific_name)
  c_name = Factory.next(:common_name)
  eukaryota = build_taxon_concept(:rank => '',
                                  :canonical_form => sci_name,
                                  :common_names => [c_name],
                                  :event => event,
                                  :hierarchy => ncbi_hierarchy,
                                  :parent_hierarchy_entry_id => parent_id,
                                  :depth => depth)
end





make_all_nested_sets
recreate_normalized_names_and_links
