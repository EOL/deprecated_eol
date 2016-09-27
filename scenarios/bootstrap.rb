# Put a few taxa (all within a new hierarchy) in the database with a range of accoutrements
#
#   TODO add a description here of what actually gets created!
#
#   This description block can be viewed (as well as other information
#   about this scenario) by running:
#     $ rake scenarios:show NAME=bootstrap
#---

# TODO - port scenarios to Rails' baked-in seeds.
$LOADING_BOOTSTRAP = true

# We turn off Solr and reindex the whole lot at the end - its faster that way
original_index_records_on_save_value = $INDEX_RECORDS_IN_SOLR_ON_SAVE
$INDEX_RECORDS_IN_SOLR_ON_SAVE = false

# Looking up the activity logs for comments is slow here as lots of comments
# are created in the bootstrap. They will get indexed en masse at the end of
# this scenario
$SKIP_CREATING_ACTIVITY_LOGS_FOR_COMMENTS = true

require Rails.root.join('spec', 'scenario_helpers.rb')
# This gives us the ability to recalculate some DB values:
include EOL::Data
# This gives us the ability to build taxon concepts:
include EOL::Builders
include ScenarioHelpers # Allows us to load other scenarios

load_foundation_cache

# A singleton that creates some users:
def bootstrap_users
  @@bootstrap_users ||= []
  return @@bootstrap_users unless @@bootstrap_users.length == 0
  12.times do
    u = User.gen
    @@bootstrap_users << u
    u.build_watch_collection
  end
  return @@bootstrap_users
end

# This used to be... random.  Now, I'm creating a small subset of the "real" TocItems.
def bootstrap_toc
  ActiveRecord::Base.transaction do
    current_order = TocItem.count # Just a reasonable place to start counting for "parent" items.
    description_labels = [
        'Brief Description',
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
    relevance = TocItem.gen_if_not_exists(label: 'Relevance', parent_id: 0, view_order: current_order += 1)
    make_toc_children(TocItem.find_by_translated(:label, 'Description').id, description_labels, current_order)
    current_order += description_labels.length+1
    TocItem.gen_if_not_exists(label: 'Reproductive Behavior', parent_id: 0, view_order: current_order += 1)
    TocItem.gen_if_not_exists(label: 'Conservation', parent_id: 0, view_order: current_order += 1)
    TocItem.gen_if_not_exists(label: 'Evolution and Systematics', parent_id: 0, view_order: current_order += 1)
    TocItem.gen_if_not_exists(label: 'Literature References', parent_id: 0, view_order: current_order += 1)
    relevance = TocItem.gen_if_not_exists(label: 'Relevance', parent_id: 0, view_order: current_order += 1)
    relevance_labels = [
      'Harmful Blooms',
      'Relation to Humans',
      'Toxicity, Symptoms and Treatment',
      'Cultivation',
      'Culture',
      'Ethnobotany',
      'Suppliers'
    ]
    make_toc_children(relevance.id, relevance_labels, current_order)
  end
end

def make_toc_children(parent_id, labels, current_order)
  labels.each do |label|
    current_order += 1
    TocItem.gen_if_not_exists(label: label, parent_id: parent_id, view_order: current_order)
  end
end

def load_old_foundation_data
  ActiveRecord::Base.transaction do
    AgentRole.gen_if_not_exists(label: 'Animator')
    AgentRole.gen_if_not_exists(label: 'Compiler')
    AgentRole.gen_if_not_exists(label: 'Composer')
    AgentRole.gen_if_not_exists(label: 'Creator')
    AgentRole.gen_if_not_exists(label: 'Director')
    AgentRole.gen_if_not_exists(label: 'Editor')
    AgentRole.gen_if_not_exists(label: 'Illustrator')
    AgentRole.gen_if_not_exists(label: 'Project')
    AgentRole.gen_if_not_exists(label: 'Publisher')
    AgentRole.gen_if_not_exists(label: 'Recorder')
    AgentRole.gen_if_not_exists(label: 'Source Database')
    AgentRole.gen_if_not_exists(label: 'Contact Person')

    InfoItem.gen_if_not_exists(schema_value: 'http://rs.tdwg.org/ontology/voc/SPMInfoItems#Associations',          label: 'Associations')
    InfoItem.gen_if_not_exists(schema_value: 'http://rs.tdwg.org/ontology/voc/SPMInfoItems#Behaviour',             label: 'Behaviour')
    InfoItem.gen_if_not_exists(schema_value: 'http://rs.tdwg.org/ontology/voc/SPMInfoItems#ConservationStatus',    label: 'ConservationStatus')
    InfoItem.gen_if_not_exists(schema_value: 'http://rs.tdwg.org/ontology/voc/SPMInfoItems#Cyclicity',             label: 'Cyclicity')
    InfoItem.gen_if_not_exists(schema_value: 'http://rs.tdwg.org/ontology/voc/SPMInfoItems#Cytology',              label: 'Cytology')
    InfoItem.gen_if_not_exists(schema_value: 'http://rs.tdwg.org/ontology/voc/SPMInfoItems#DiagnosticDescription', label: 'DiagnosticDescription')
    InfoItem.gen_if_not_exists(schema_value: 'http://rs.tdwg.org/ontology/voc/SPMInfoItems#Diseases',              label: 'Diseases')
    InfoItem.gen_if_not_exists(schema_value: 'http://rs.tdwg.org/ontology/voc/SPMInfoItems#Dispersal',             label: 'Dispersal')
    InfoItem.gen_if_not_exists(schema_value: 'http://rs.tdwg.org/ontology/voc/SPMInfoItems#Evolution',             label: 'Evolution')
    InfoItem.gen_if_not_exists(schema_value: 'http://rs.tdwg.org/ontology/voc/SPMInfoItems#Genetics',              label: 'Genetics')
    InfoItem.gen_if_not_exists(schema_value: 'http://rs.tdwg.org/ontology/voc/SPMInfoItems#Growth',                label: 'Growth')
    InfoItem.gen_if_not_exists(schema_value: 'http://rs.tdwg.org/ontology/voc/SPMInfoItems#Habitat',               label: 'Habitat')
    InfoItem.gen_if_not_exists(schema_value: 'http://rs.tdwg.org/ontology/voc/SPMInfoItems#Legislation',           label: 'Legislation')
    InfoItem.gen_if_not_exists(schema_value: 'http://rs.tdwg.org/ontology/voc/SPMInfoItems#LifeCycle',             label: 'LifeCycle')
    InfoItem.gen_if_not_exists(schema_value: 'http://rs.tdwg.org/ontology/voc/SPMInfoItems#LifeExpectancy',        label: 'LifeExpectancy')
    InfoItem.gen_if_not_exists(schema_value: 'http://rs.tdwg.org/ontology/voc/SPMInfoItems#LookAlikes',            label: 'LookAlikes')
    InfoItem.gen_if_not_exists(schema_value: 'http://rs.tdwg.org/ontology/voc/SPMInfoItems#Management',            label: 'Management')
    InfoItem.gen_if_not_exists(schema_value: 'http://rs.tdwg.org/ontology/voc/SPMInfoItems#Migration',             label: 'Migration')
    InfoItem.gen_if_not_exists(schema_value: 'http://rs.tdwg.org/ontology/voc/SPMInfoItems#MolecularBiology',      label: 'MolecularBiology')
    InfoItem.gen_if_not_exists(schema_value: 'http://rs.tdwg.org/ontology/voc/SPMInfoItems#Morphology',            label: 'Morphology')
    InfoItem.gen_if_not_exists(schema_value: 'http://rs.tdwg.org/ontology/voc/SPMInfoItems#Physiology',            label: 'Physiology')
    InfoItem.gen_if_not_exists(schema_value: 'http://rs.tdwg.org/ontology/voc/SPMInfoItems#PopulationBiology',     label: 'PopulationBiology')
    InfoItem.gen_if_not_exists(schema_value: 'http://rs.tdwg.org/ontology/voc/SPMInfoItems#Procedures',            label: 'Procedures')
    InfoItem.gen_if_not_exists(schema_value: 'http://rs.tdwg.org/ontology/voc/SPMInfoItems#Reproduction',          label: 'Reproduction')
    InfoItem.gen_if_not_exists(schema_value: 'http://rs.tdwg.org/ontology/voc/SPMInfoItems#RiskStatement',         label: 'RiskStatement')
    InfoItem.gen_if_not_exists(schema_value: 'http://rs.tdwg.org/ontology/voc/SPMInfoItems#Size',                  label: 'Size')
    InfoItem.gen_if_not_exists(schema_value: 'http://rs.tdwg.org/ontology/voc/SPMInfoItems#Threats',               label: 'Threats')
    InfoItem.gen_if_not_exists(schema_value: 'http://rs.tdwg.org/ontology/voc/SPMInfoItems#Trends',                label: 'Trends')
    InfoItem.gen_if_not_exists(schema_value: 'http://rs.tdwg.org/ontology/voc/SPMInfoItems#TrophicStrategy',       label: 'TrophicStrategy')
    InfoItem.gen_if_not_exists(schema_value: 'http://rs.tdwg.org/ontology/voc/SPMInfoItems#Uses',                  label: 'Uses')

    MimeType.gen_if_not_exists(label: 'audio/mpeg')
    MimeType.gen_if_not_exists(label: 'audio/x-ms-wma')
    MimeType.gen_if_not_exists(label: 'audio/x-pn-realaudio')
    MimeType.gen_if_not_exists(label: 'audio/x-realaudio')
    MimeType.gen_if_not_exists(label: 'audio/x-wav')
    MimeType.gen_if_not_exists(label: 'image/bmp')
    MimeType.gen_if_not_exists(label: 'image/gif')
    MimeType.gen_if_not_exists(label: 'image/png')
    MimeType.gen_if_not_exists(label: 'image/svg+xml')
    MimeType.gen_if_not_exists(label: 'image/tiff')
    MimeType.gen_if_not_exists(label: 'text/html')
    MimeType.gen_if_not_exists(label: 'text/plain')
    MimeType.gen_if_not_exists(label: 'text/richtext')
    MimeType.gen_if_not_exists(label: 'text/rtf')
    MimeType.gen_if_not_exists(label: 'text/xml')
    MimeType.gen_if_not_exists(label: 'video/mp4')
    MimeType.gen_if_not_exists(label: 'video/mpeg')
    MimeType.gen_if_not_exists(label: 'video/quicktime')
    MimeType.gen_if_not_exists(label: 'video/x-ms-wmv')

    RefIdentifierType.gen_if_not_exists(label: 'bici')
    RefIdentifierType.gen_if_not_exists(label: 'coden')
    RefIdentifierType.gen_if_not_exists(label: 'doi')
    RefIdentifierType.gen_if_not_exists(label: 'eissn')
    RefIdentifierType.gen_if_not_exists(label: 'handle')
    RefIdentifierType.gen_if_not_exists(label: 'isbn')
    RefIdentifierType.gen_if_not_exists(label: 'issn')
    RefIdentifierType.gen_if_not_exists(label: 'lsid')
    RefIdentifierType.gen_if_not_exists(label: 'oclc')
    RefIdentifierType.gen_if_not_exists(label: 'sici')
    RefIdentifierType.gen_if_not_exists(label: 'urn')

    ResourceStatus.gen_if_not_exists(label: 'Uploading')
    ResourceStatus.gen_if_not_exists(label: 'Uploaded')
    ResourceStatus.gen_if_not_exists(label: 'Upload Failed')
    ResourceStatus.gen_if_not_exists(label: 'Moved to Content Server')
    ResourceStatus.gen_if_not_exists(label: 'Validated')
    ResourceStatus.gen_if_not_exists(label: 'Validation Failed')
    ResourceStatus.gen_if_not_exists(label: 'Being Processed')
    ResourceStatus.gen_if_not_exists(label: 'Processed')
    ResourceStatus.gen_if_not_exists(label: 'Processing Failed')
    ResourceStatus.gen_if_not_exists(label: 'Harvest Requested')
    ResourceStatus.gen_if_not_exists(label: 'Published')

    SynonymRelation.gen_if_not_exists(label: "acronym")
    SynonymRelation.gen_if_not_exists(label: "anamorph")
    SynonymRelation.gen_if_not_exists(label: "blast name")
    SynonymRelation.gen_if_not_exists(label: "equivalent name")
    SynonymRelation.gen_if_not_exists(label: "genbank acronym")
    SynonymRelation.gen_if_not_exists(label: "genbank anamorph")
    SynonymRelation.gen_if_not_exists(label: "genbank synonym")
    SynonymRelation.gen_if_not_exists(label: "in-part")
    SynonymRelation.gen_if_not_exists(label: "includes")
    SynonymRelation.gen_if_not_exists(label: "misnomer")
    SynonymRelation.gen_if_not_exists(label: "misspelling")
    SynonymRelation.gen_if_not_exists(label: "teleomorph")
    SynonymRelation.gen_if_not_exists(label: "ambiguous synonym")
    SynonymRelation.gen_if_not_exists(label: "misapplied name")
    SynonymRelation.gen_if_not_exists(label: "provisionally accepted name")
    SynonymRelation.gen_if_not_exists(label: "accepted name")
    SynonymRelation.gen_if_not_exists(label: "database artifact")
    SynonymRelation.gen_if_not_exists(label: "other, see comments")
    SynonymRelation.gen_if_not_exists(label: "orthographic variant (misspelling)")
    SynonymRelation.gen_if_not_exists(label: "misapplied")
    SynonymRelation.gen_if_not_exists(label: "rejected name")
    SynonymRelation.gen_if_not_exists(label: "homonym (illegitimate)")
    SynonymRelation.gen_if_not_exists(label: "pro parte")
    SynonymRelation.gen_if_not_exists(label: "superfluous renaming (illegitimate)")
    SynonymRelation.gen_if_not_exists(label: "nomen oblitum")
    SynonymRelation.gen_if_not_exists(label: "junior synonym")
    SynonymRelation.gen_if_not_exists(label: "unavailable, database artifact")
    SynonymRelation.gen_if_not_exists(label: "unnecessary replacement")
    SynonymRelation.gen_if_not_exists(label: "subsequent name/combination")
    SynonymRelation.gen_if_not_exists(label: "unavailable, literature misspelling")
    SynonymRelation.gen_if_not_exists(label: "original name/combination")
    SynonymRelation.gen_if_not_exists(label: "unavailable, incorrect orig. spelling")
    SynonymRelation.gen_if_not_exists(label: "junior homonym")
    SynonymRelation.gen_if_not_exists(label: "homonym & junior synonym")
    SynonymRelation.gen_if_not_exists(label: "unavailable, suppressed by ruling")
    SynonymRelation.gen_if_not_exists(label: "unjustified emendation")
    SynonymRelation.gen_if_not_exists(label: "unavailable, other")
    SynonymRelation.gen_if_not_exists(label: "unavailable, nomen nudum")
    SynonymRelation.gen_if_not_exists(label: "nomen dubium")
    SynonymRelation.gen_if_not_exists(label: "invalidly published, other")
    SynonymRelation.gen_if_not_exists(label: "invalidly published, nomen nudum")
    SynonymRelation.gen_if_not_exists(label: "basionym")
    SynonymRelation.gen_if_not_exists(label: "heterotypic synonym")
    SynonymRelation.gen_if_not_exists(label: "homotypic synonym")
    SynonymRelation.gen_if_not_exists(label: "unavailable name")
    SynonymRelation.gen_if_not_exists(label: "valid name")
  end
end



#### Real work begins
bootstrap_toc

### some data pulled out of foundation
load_old_foundation_data

ActiveRecord::Base.transaction do
  # TODO - I am neglecting to set up agent content partners, curators, contacts, provided data types, or agreements.  For now.
  agent_col = Agent.catalogue_of_life
  agent_col.user ||= User.gen
  if agent_col.user.content_partners.blank?
    agent_col.user.content_partners << ContentPartner.gen(full_name: "Catalogue of Life")
  end
  resource = Resource.gen(title: 'Bootstrapper', resource_status: ResourceStatus.processed,
    hierarchy: Hierarchy.find_by_label('Species 2000 & ITIS Catalogue of Life: Annual Checklist 2010'),
    content_partner: agent_col.user.content_partners.first, vetted: true)
  event    = HarvestEvent.gen(resource: resource)

  gbif_agent = Agent.gen(full_name: "Global Biodiversity Information Facility (GBIF)")
  #gbif_agent = Agent.find_by_full_name('Global Biodiversity Information Facility (GBIF)');
  gbif_agent.user ||= User.gen
  gbif_cp    = ContentPartner.gen user: gbif_agent.user, full_name: "Global Biodiversity Information Facility (GBIF)"
  ContentPartnerContact.gen(content_partner: gbif_cp, contact_role: ContactRole.primary)
  gbif_hierarchy = Hierarchy.gen(agent: gbif_agent, label: "GBIF Nub Taxonomy")

  kingdom = build_taxon_concept(rank: 'kingdom', canonical_form: 'Animalia', event: event)
  kingdom.add_common_name_synonym('Animals', agent: agent_col, language: Language.english)

  4.times do
    tc = build_taxon_concept(parent_hierarchy_entry_id: Hierarchy.default.hierarchy_entries.last.id,
                             depth: Hierarchy.default.hierarchy_entries.length,
                             event: event)
    tc.add_common_name_synonym(FactoryGirl.generate(:common_name), agent: agent_col, language: Language.english)
  end

  fifth_entry_id = Hierarchy.default.hierarchy_entries.last.id
  depth_now      = Hierarchy.default.hierarchy_entries.length

  # NOTE!  I am going to use HARDCODED common names *JUST* so that searching will have multiple results for one string.

  # Sixth Taxon should have more images, and have videos:
  tc = build_taxon_concept(parent_hierarchy_entry_id: fifth_entry_id,
                           depth: depth_now, images: :testing, event: event)
  tc.add_common_name_synonym('Tiger moth', agent: agent_col, language: Language.english)

  #TODO: omg this is HORRIBLE!
  # While I'm at it, though, I am *also* giving this user the same email address as another user.
  last_user = User.last
  u = User.gen(email: last_user.email)
  taxon_concept_image = tc.data_objects.find(:all, conditions: "data_type_id IN (#{DataType.image_type_ids.join(',')})").first
  taxon_concept_image.comments[0].body = 'First comment'
  taxon_concept_image.comments[0].save!
  taxon_concept_image.comment(u, 'Second comment')
  taxon_concept_image.comment(u, 'Third comment')
  taxon_concept_image.comment(u, 'Forth comment')
  taxon_concept_image.comment(u, 'Fifth comment')
  taxon_concept_image.comment(u, 'Sixth comment')
  taxon_concept_image.comment(u, 'Seventh comment')
  taxon_concept_image.comment(u, 'Eighth comment')
  taxon_concept_image.comment(u, 'Nineth comment')
  taxon_concept_image.comment(u, 'Tenth comment')
  taxon_concept_image.comment(u, 'Eleventh comment')
  taxon_concept_image.comment(u, 'Twelveth comment')

  # Seventh Taxon (sign of the apocolypse?) should be a child of fifth and be "empty", other than common names:
  tc = build_taxon_concept(parent_hierarchy_entry_id: fifth_entry_id,
                           depth: depth_now,
                           images: [],
                           toc: [],
                           flash: [],
                           youtube: [],
                           comments: [],
                           bhl: [],
                           event: event,
                           vetted: 'untrusted')
  tc.add_common_name_synonym('Tiger lilly', agent: agent_col, language: Language.english)
  # We want this one to have a higher Solr search weight for 'tiger', so give it lots of permutations:
  tc.add_common_name_synonym('Tiger water lilly', agent: agent_col, language: Language.english)
  tc.add_common_name_synonym('lilly of the tiger', agent: agent_col, language: Language.english)
  tc.add_common_name_synonym('Tiger flower', agent: agent_col, language: Language.english)
  tc.add_common_name_synonym('Tiger-stripe lilly', agent: agent_col, language: Language.english)
  tc.add_common_name_synonym('Tiger-eye lilly', agent: agent_col, language: Language.english)

  # Eighth Taxon (now we're just getting greedy) should be the same as Seven, but with BHL:
  tc = build_taxon_concept(parent_hierarchy_entry_id: fifth_entry_id,
                           depth: depth_now,
                           images: [],
                           toc: [],
                           flash: [],
                           youtube: [],
                           comments: [],
                           event: event,
                           vetted: 'unknown')
  tc.add_common_name_synonym('Tiger', agent: agent_col, language: Language.english)

  # Ninth Taxon is *totally* naked:
  build_taxon_concept(parent_hierarchy_entry_id: fifth_entry_id, common_names: [], bhl: [], event: event,
                      depth: depth_now, images: [], toc: [], flash: [], youtube: [], comments: [])

  #30 has unvetted images and videos, overview and description TOC, please don't change this one, needed for selenum tests:
  tc30 = build_taxon_concept(parent_hierarchy_entry_id: fifth_entry_id,
                      depth:    depth_now,
                      images:   :testing,
                      flash:    [{vetted: Vetted.untrusted}],
                      youtube:  [{vetted: Vetted.untrusted}],
                      comments: [],
                      bhl:      [],
                      event:    event)

  tc30.add_common_name_synonym(FactoryGirl.generate(:common_name), agent: agent_col, language: Language.english)

  #31 has unvetted and vetted videos, please don't change this one, needed for selenum test:
  overv = TocItem.find_by_translated(:label, 'Overview')
  desc = TocItem.find_by_translated(:label, 'Description')
  tc31 = build_taxon_concept(parent_hierarchy_entry_id: fifth_entry_id, common_names: [FactoryGirl.generate(:common_name)],
                    depth: depth_now,
                    flash: [{}, {vetted: Vetted.unknown}],
                    youtube: [{vetted: Vetted.unknown},
                                 {vetted: Vetted.untrusted}],
                    comments: [],
                    bhl: [],
                    event: event,
                    toc: [{
                      toc_item: overv,
                      description: 'overview text for re-harvest'
                      },
                      {
                      toc_item: desc,
                      description: 'description text for re-harvest'
                      }],
                    images: [{
                      description: '1st image description for re-harvest'
                      }]
  )

  curator_for_tc31 = build_curator(tc31, username: 'curator_for_tc', password: 'password')
  text_dato = tc31.data_objects.select{ |d| d.is_text? }.first
  image_dato = tc31.data_objects.select{ |d| d.is_image? }.first

  # rating of old version of dato was 1
  text_dato.rate(curator_for_tc31, 1)
  image_dato.rate(curator_for_tc31, 1)
  # create new dato with the same guid and comments on new version
  add_comments_to_reharvested_data_objects(tc31)

  #32
  user = User.gen
  user.build_watch_collection
  overv = TocItem.find_by_translated(:label, 'Overview')
  desc = TocItem.find_by_translated(:label, 'Description')
  tc = build_taxon_concept(toc: [{toc_item: overv}, {toc_item: overv}, {toc_item: desc}], comments: [{}])
  description_dato = tc.data_objects.select{ |d| d.is_text? && d.toc_items.include?(desc) }.first
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

  DataObjectsInfoItem.gen(data_object: tc.data_objects.select{ |d| d.is_text? }.first, info_item: InfoItem.find_by_translated(:label, "Cyclicity"))
  DataObjectsInfoItem.gen(data_object: tc.data_objects.select{ |d| d.is_text? }.last, info_item: InfoItem.find_by_translated(:label, "Distribution"))



  # create a content_partner that we can log in as for testing (user:password = testcp:testcp)
  cp_user = User.gen(username: 'testcp', password: 'testcp', given_name: 'Ralph', family_name: 'Wiggum')
  cp_user.build_watch_collection
  cp = ContentPartner.gen(user: cp_user,
                          full_name: 'Partner name',
                          description: 'description of the partner')
  ac = ContentPartnerContact.gen(content_partner: cp, contact_role: ContactRole.primary)



  # Now that we're done with CoL, we add another content partner who overlaps with them:
         # Give it a new name:
  name   = Name.gen(canonical_form: tc.entry.canonical_form)#, string: n = FactoryGirl.generate(:scientific_name),
                    # italicized:      "<i>#{n}</i> #{FactoryGirl.generate(:attribution)}")
  agent2 = Agent.gen
  agent2.user ||= User.gen(agent: agent2, username: 'test_cp')
  cp     = ContentPartner.gen user: agent2.user, full_name: 'Test ContenPartner'
  cont   = ContentPartnerContact.gen content_partner: cp, contact_role: ContactRole.primary
  r2     = Resource.gen(title: 'Test ContentPartner import', vetted: true, resource_status: ResourceStatus.processed, content_partner: cp)
  ev2    = HarvestEvent.gen(resource: r2)
  hier   = Hierarchy.gen agent: agent2
  he     = build_hierarchy_entry 0, tc, name, hierarchy: hier
  img    = build_data_object('Image', "This should only be seen by ContentPartner #{cp.description}",
                             hierarchy_entry: he,
                             object_cache_url: FactoryGirl.generate(:image),
                             vetted: Vetted.unknown,
                             visibility: Visibility.preview)

  # Some node in the GBIF Hierarchy to test maps on
  build_hierarchy_entry 0, tc, name, hierarchy: gbif_hierarchy, identifier: '13810203'

  # Generate a default admin user and then set them up:
  admin = build_curator(@taxon_concept, username: 'admin', password: 'admin', given_name: 'Admin', family_name: 'User', level: :master)
  admin.grant_admin
  admin.grant_permission(:edit_permissions)
  admin.grant_permission(:see_data)
  admin.build_watch_collection

  exemplar = build_taxon_concept(event: event,
                                 common_names: ['wumpus', 'wompus', 'wampus'],
                                 biomedical_terms: true) # LigerCat powers, ACTIVATE!

  # Genereate a curator user
  curator = build_curator(tc30, username: 'test_curator', password: 'password', given_name: 'test', family_name: 'curator')



  # Adds a ContentPage at the following URL: http://localhost:3000/content/page/curator_central

  ContentPage.gen_if_not_exists(page_name: "curator_central", title: "Curator central", left_content: "", sort_order: 7)

  # TODO - we need to build TopImages such that ancestors contain the images of their descendants

  # creating collection / mapping data
  image_collection_type = CollectionType.gen_if_not_exists(label: "Images")
  specimen_image_collection_type = CollectionType.gen_if_not_exists(label: "Specimen", parent_id: image_collection_type.id)
  natural_image_collection_type = CollectionType.gen_if_not_exists(label: "Natural", parent_id: image_collection_type.id)

  species_pages_collection_type = CollectionType.gen_if_not_exists(label: "Species Pages")
  molecular_species_pages_collection_type = CollectionType.gen_if_not_exists(label: "Molecular", parent_id: species_pages_collection_type.id)
  novice_pages_collection_type = CollectionType.gen_if_not_exists(label: "Novice", parent_id: species_pages_collection_type.id)
  expert_pages_collection_type = CollectionType.gen_if_not_exists(label: "Expert", parent_id: species_pages_collection_type.id)

  marine_theme_collection_type = CollectionType.gen_if_not_exists(label: "Marine")
  bugs_theme_collection_type = CollectionType.gen_if_not_exists(label: "Bugs")

  specimen_image_hierarchy = Hierarchy.gen(label: 'AntWeb', description: 'Currently AntWeb contains information on the ant faunas of several areas in the Nearctic and Malagasy biogeographic regions, and global coverage of all ant genera.', outlink_uri: 'http://www.antweb.org/specimen.do?name=%%ID%%', url: 'http://www.antweb.org/')
  CollectionTypesHierarchy.gen(hierarchy: specimen_image_hierarchy, collection_type: specimen_image_collection_type)
  CollectionTypesHierarchy.gen(hierarchy: specimen_image_hierarchy, collection_type: expert_pages_collection_type)
  CollectionTypesHierarchy.gen(hierarchy: specimen_image_hierarchy, collection_type: bugs_theme_collection_type)
  HierarchyEntry.gen(hierarchy: specimen_image_hierarchy, name: kingdom.entry.name, identifier: 'casent0129891', taxon_concept: kingdom)
  HierarchyEntry.gen(hierarchy: specimen_image_hierarchy, name: kingdom.entry.name, identifier: 'casent0496198', taxon_concept: kingdom)
  HierarchyEntry.gen(hierarchy: specimen_image_hierarchy, name: kingdom.entry.name, identifier: 'casent0179524', taxon_concept: kingdom)

  molecular_species_pages_hierarchy = Hierarchy.gen(
    label: 'National Center for Biotechnology Information',
    description: 'Established in 1988 as a national resource for molecular biology information, NCBI creates public databases, conducts research in computational biology, develops software tools for analyzing genome data, and disseminates biomedical information - all for the better understanding of molecular processes affecting human health and disease',
    outlink_uri: 'http://www.ncbi.nlm.nih.gov/sites/entrez?Db=genomeprj&cmd=ShowDetailView&TermToSearch=%%ID%%',
    url: 'http://www.ncbi.nlm.nih.gov/')
  CollectionTypesHierarchy.gen(hierarchy: molecular_species_pages_hierarchy, collection_type: molecular_species_pages_collection_type)
  CollectionTypesHierarchy.gen(hierarchy: molecular_species_pages_hierarchy, collection_type: marine_theme_collection_type)
  HierarchyEntry.gen(hierarchy: molecular_species_pages_hierarchy, name: kingdom.entry.name, identifier: '13646', taxon_concept: kingdom)
  HierarchyEntry.gen(hierarchy: molecular_species_pages_hierarchy, name: kingdom.entry.name, identifier: '9551', taxon_concept: kingdom)

  r = Rank.gen_if_not_exists(label: 'superkingdom', rank_group_id: 0)


  ### Adding another hierarchy to test switching from one to another
  Agent.ncbi.user ||= User.gen(agent: Agent.ncbi)
  if Agent.ncbi.user.content_partners.blank?
    Agent.ncbi.user.content_partners << ContentPartner.gen(user: Agent.ncbi.user, full_name: "NCBI")
  end
  ContentPartnerContact.gen(content_partner: Agent.ncbi.user.content_partners.first, contact_role: ContactRole.primary)

  eukaryota = build_taxon_concept(rank: 'superkingdom',
                                  canonical_form: 'Eukaryota',
                                  common_names: ['eukaryotes'],
                                  event: event,
                                  hierarchy: Hierarchy.ncbi,
                                  depth: 0)

  opisthokonts_name   = Name.gen(canonical_form: cf = CanonicalForm.gen(string: 'Metazoa'),
                    string: 'Metazoa',
                    italicized: '<i>Metazoa</i>')
  opisthokonts_common_name   = Name.gen(canonical_form: cf = CanonicalForm.gen(string: 'opisthokonts'),
                    string: 'opisthokonts',
                    italicized: '<i>opisthokonts</i>')
  opisthokonts = build_hierarchy_entry(0, kingdom, opisthokonts_name,
              rank_id: Rank.find_by_translated(:label, 'kingdom').id,
              identifier: 33154,
              parent_id: Hierarchy.ncbi.hierarchy_entries.last.id,
              hierarchy: Hierarchy.ncbi )
  TaxonConceptName.gen(preferred: true, vern: true, source_hierarchy_entry_id: opisthokonts.id, language: Language.english,
                      name: opisthokonts_common_name, taxon_concept: kingdom, vetted_id: Vetted.trusted.id)
  TaxonConceptName.gen(preferred: true, vern: false, source_hierarchy_entry_id: opisthokonts.id, language: Language.scientific,
                       name: opisthokonts_name, taxon_concept: kingdom, vetted_id: Vetted.trusted.id)

  4.times do
    parent_id = Hierarchy.ncbi.hierarchy_entries.last.id
    depth = Hierarchy.ncbi.hierarchy_entries.last.depth + 1

    2.times do
      sci_name = FactoryGirl.generate(:scientific_name)
      c_name = FactoryGirl.generate(:common_name)
      build_taxon_concept(rank: '',
                          canonical_form: sci_name,
                          common_names: [c_name],
                          event: event,
                          hierarchy: Hierarchy.ncbi,
                          parent_hierarchy_entry_id: parent_id,
                          depth: depth)
    end

  end


  bacteria = build_taxon_concept(rank: 'superkingdom',
                                  canonical_form: 'Bacteria',
                                  event: event,
                                  hierarchy: Hierarchy.ncbi,
                                  depth: 0)

  # We need to be able to test changing the preferred name across several languages:
  english = Language.english
  bacteria.add_common_name_synonym("bacteria", agent: agent_col, language: english, preferred: true)
  bacteria.add_common_name_synonym("bugs", agent: agent_col, language: english, preferred: false)
  bacteria.add_common_name_synonym("grime", agent: agent_col, language: english, preferred: false)
  bacteria.add_common_name_synonym("critters", agent: agent_col, language: english, preferred: false)
  german  = Language.gen_if_not_exists(label: 'German', iso_639_1: 'de')
  bacteria.add_common_name_synonym("bakteria", agent: agent_col, language: german, preferred: true)
  bacteria.add_common_name_synonym("die buggen", agent: agent_col, language: german, preferred: false)
  bacteria.add_common_name_synonym("das greim", agent: agent_col, language: german, preferred: false)
  french = Language.find_by_translated(:label, 'French') # Assumes French was defined in foundation
  bacteria.add_common_name_synonym("baseteir", agent: agent_col, language: french, preferred: true)
  bacteria.add_common_name_synonym("le grimme", agent: agent_col, language: french, preferred: false)
  bacteria.add_common_name_synonym("ler petit bugge", agent: agent_col, language: french, preferred: false)

  bacteria.add_scientific_name_synonym('microbia')

  4.times do
    parent_id = Hierarchy.ncbi.hierarchy_entries.last.id
    depth = Hierarchy.ncbi.hierarchy_entries.last.depth + 1

    sci_name = FactoryGirl.generate(:scientific_name)
    c_name = FactoryGirl.generate(:common_name)
    build_taxon_concept(rank: '',
                        canonical_form: sci_name,
                        common_names: [c_name],
                        event: event,
                        hierarchy: Hierarchy.ncbi,
                        parent_hierarchy_entry_id: parent_id,
                        depth: depth)
  end

  # delete all concepts with no hierarchy entries
  TaxonConcept.find_each do |tc|
    if tc.hierarchy_entries.empty?
      TaxonConcept.delete(tc.id)
    end
  end



  # NOTE: the join table between this and toc items will end up with a lot of orphans in it, but I don't really care for now.
  ContentTable.delete_all
  ContentTable.create_details

  EOL::Data.make_all_nested_sets
  EOL::Data.rebuild_collection_type_nested_set
  EOL::Data.flatten_hierarchies

  # NOTE - don't use DATE_SUB in MySQL.  It's retarded when it comes to DST.  This is never run in prod, so...
  DataObject.find_each do |dato|
    begin
      dato.update_attribute(:updated_at, dato.id.hours.ago) 
    rescue ActiveRecord::StatementInvalid
      dato.update_attribute(:updated_at, (dato.id + 2).hours.ago) 
    end
  end
  Comment.find_each do |comment|
    begin
      comment.update_attribute(:updated_at, comment.id.hours.ago)
    rescue ActiveRecord::StatementInvalid
      comment.update_attribute(:updated_at, (comment.id + 2).hours.ago)
    end
  end

  (-12..12).each do |n|
    date = n.month.ago
    year = date.year
    month = date.month
    GoogleAnalyticsPartnerSummary.gen(year: year, month: month, user: Agent.catalogue_of_life.user)
    GoogleAnalyticsSummary.gen(year: year, month: month)
    GoogleAnalyticsPageStat.gen(year: year, month: month, taxon_concept: tc30 )
    GoogleAnalyticsPartnerTaxon.gen(year: year, month: month, taxon_concept: tc30, user: Agent.catalogue_of_life.user )
  end

  # Create a collection with a EOL collection id which already has a project on iNaturalist.
  c = Collection.gen(id: 5709, name: 'Cape Cod')
  c.users = [User.gen]
  c.add(DataObject.gen)

  EOL::Solr::DataObjectsCoreRebuilder.begin_rebuild
  EOL::Solr::SiteSearchCoreRebuilder.begin_rebuild
  EOL::Solr::CollectionItemsCoreRebuilder.begin_rebuild

  # Creating images for the march of life
  RandomHierarchyImage.delete_all
  TaxonConceptExemplarImage.delete_all
  TaxonConcept.where('published = 1').each do |tc|
    if image = tc.data_objects.select{ |d| d.is_image? }.first
      if dohe = image.data_objects_hierarchy_entries.first
        RandomHierarchyImage.gen(hierarchy: dohe.hierarchy_entry.hierarchy, hierarchy_entry: dohe.hierarchy_entry, data_object: image, taxon_concept: tc);
        TaxonConceptExemplarImage.gen(taxon_concept: tc, data_object: image)
      end
    end
  end

  datauser = User.gen(username: 'datamama')
  datauser.grant_permission(:see_data)
end

$INDEX_RECORDS_IN_SOLR_ON_SAVE = original_index_records_on_save_value
$SKIP_CREATING_ACTIVITY_LOGS_FOR_COMMENTS = false

$LOADING_BOOTSTRAP = false
