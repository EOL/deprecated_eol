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

resource = Resource.gen(:title => 'Bootstrapper', :resource_status => ResourceStatus.published)
event    = HarvestEvent.gen(:resource => resource)
AgentsResource.gen(:agent => Agent.catalogue_of_life, :resource => resource,
                   :resource_agent_role => ResourceAgentRole.content_partner_upload_role)
AgentsResource.gen(:agent => Agent.iucn, :resource => Resource.iucn[0],
                   :resource_agent_role => ResourceAgentRole.content_partner_upload_role)

gbif_agent = Agent.gen(:full_name => "Global Biodiversity Information Facility (GBIF)")
#gbif_agent = Agent.find_by_full_name('Global Biodiversity Information Facility (GBIF)');
AgentContact.gen(:agent => gbif_agent, :agent_contact_role => AgentContactRole.primary)
gbif_hierarchy = Hierarchy.gen(:agent => gbif_agent, :label => "GBIF Nub Taxonomy")

kingdom = build_taxon_concept(:rank => 'kingdom', :canonical_form => 'Animalia', :common_name => 'Animals')
5.times do
  build_taxon_concept(:parent_hierarchy_entry_id => Hierarchy.default.hierarchy_entries.last.id,
                      :depth => Hierarchy.default.hierarchy_entries.length)
end

# Now that we're done with CoL, we add another content partner who overlaps with them:
tc     = TaxonConcept.last # Whatever.
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
img    = build_data_object('Image', "This should only be seen by ContentPartner #{cp.description}", :taxon => tc.images.first.taxa[0],
                           :hierarchy_entry => he, :object_cache_url => Factory.next(:image), :vetted => Vetted.unknown,
                           :visibility => Visibility.preview)

# Some node in the GBIF Hierarchy to test maps on
build_hierarchy_entry 0, tc, name, :hierarchy => gbif_hierarchy, :identifier => '13810203'

# Generate a default admin user and then set them up for the default roles:
admin = User.gen :username => 'admin', :password => 'admin', :given_name => 'Admin', :family_name => 'User'
admin.roles = Role.find(:all, :conditions => 'title LIKE "Administrator%"')
admin.save

make_all_nested_sets
recreate_normalized_names_and_links

exemplar = build_taxon_concept(:id => 910093) # That ID is one of the (hard-coded) exemplars.

# TODO - we need to build TopImages such that ancestors contain the images of their descendants
