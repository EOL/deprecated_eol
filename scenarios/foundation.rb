# encoding: utf-8
# sets up a basic foundation - enough data to run the application, but no content
truncate_all_tables(:skip_empty_tables => false) rescue nil # We do this to make sure the IDs on all of the tables start at 1.

Rails.cache.clear # because we are resetting everything!  Sometimes, say, iucn is set.

original_index_records_on_save_value = $INDEX_RECORDS_IN_SOLR_ON_SAVE
$INDEX_RECORDS_IN_SOLR_ON_SAVE = false

# Translated tables will not work without this:
Language.create_english

ContentPage.gen_if_not_exists(:page_name => 'Home', :title => 'Home', :sort_order => 1)
ContentPage.gen_if_not_exists(:page_name => 'Who We Are', :title => 'Who We Are', :sort_order => 2)
ContentPage.gen_if_not_exists(:page_name => 'Working Groups', :title => 'Working Groups',
  :parent_content_page => ContentPage.gen_if_not_exists(:page_name => 'Who We Are'))
ContentPage.gen_if_not_exists(:page_name => 'Working Group A', :title => 'Working Group A',
  :sort_order => 1, :parent_content_page => ContentPage.gen_if_not_exists(:page_name => 'Working Groups'))
ContentPage.gen_if_not_exists(:page_name => 'Working Group B', :title => 'Working Group B',
  :sort_order => 2, :parent_content_page => ContentPage.gen_if_not_exists(:page_name => 'Working Groups'))
ContentPage.gen_if_not_exists(:page_name => 'Working Group C', :title => 'Working Group C',
  :sort_order => 3, :parent_content_page => ContentPage.gen_if_not_exists(:page_name => 'Working Groups'))
ContentPage.gen_if_not_exists(:page_name => 'Working Group D', :title => 'Working Group D',
  :sort_order => 4, :parent_content_page => ContentPage.gen_if_not_exists(:page_name => 'Working Groups'))
ContentPage.gen_if_not_exists(:page_name => 'Working Group E', :title => 'Working Group E',
  :sort_order => 5, :parent_content_page => ContentPage.gen_if_not_exists(:page_name => 'Working Groups'))
ContentPage.gen_if_not_exists(:page_name => 'Contact Us', :title => 'Contact Us', :sort_order => 3)
ContentPage.gen_if_not_exists(:page_name => 'Screencasts', :title => 'Screencasts', :sort_order => 4)
ContentPage.gen_if_not_exists(:page_name => 'Press Releases', :title => 'Press Releases', :sort_order => 5)
ContentPage.gen_if_not_exists(:page_name => 'terms_of_use', :title => 'Terms of Use', :sort_order => 6)

['Membership and registration', 'Terms of use and licensing', 'Learning and education',
 'Become a content partner', 'Content partner support', 'Curator support',
 'Make a correction (spelling and grammar, images, information)', 'Contribute images, videos or sounds',
 'Media requests (interviews, press inquiries, logo requests)', 'Make a financial donation',
 'Technical questions (problems with search, website functionality)',
 'General feedback'].each do |contact_subject_title|
  ContactSubject.gen_if_not_exists(:title => contact_subject_title, :recipients => "junk@example.com", :active => 1)
end

Activity.create_defaults

# create_if_not_exists We don't technically *need* all three of these, but it's nice to have for the menu.  There are more, but we don't currently use
# them.  create_if_not_exists Once we do, they should get added here.
ContactRole.gen_if_not_exists(:label => 'Primary Contact')
ContactRole.gen_if_not_exists(:label => 'Administrative Contact')
ContactRole.gen_if_not_exists(:label => 'Technical Contact')

# Cannot create users without special collection:
SpecialCollection.create_all
CuratorCommunity.build
SortStyle.create_defaults # Need this to make communities.
ViewStyle.create_defaults # Used by collections views

CuratorLevel.create_defaults
UserIdentity.create_defaults

iucn_agent = Agent.gen_if_not_exists(:full_name => 'IUCN')
iucn_user = User.gen_if_not_exists(:given_name => 'IUCN', :agent => iucn_agent)
iucn_content_parter = ContentPartner.gen_if_not_exists(:user => iucn_user, :full_name => 'IUCN' )
ContentPartnerContact.gen_if_not_exists(:content_partner => iucn_content_parter, :contact_role => ContactRole.primary)

col_agent = Agent.gen_if_not_exists(:full_name => 'Catalogue of Life', :logo_cache_url => '219000', :homepage => 'http://www.catalogueoflife.org/')
col_user = User.gen_if_not_exists(:display_name => 'Catalogue of Life', :agent => col_agent)
col_content_partner = ContentPartner.gen_if_not_exists(:user => col_user, :full_name => 'Catalogue of Life')
ContentPartnerContact.gen_if_not_exists(:content_partner => col_content_partner, :contact_role => ContactRole.primary)

Agent.gen_if_not_exists(:full_name => 'National Center for Biotechnology Information', :acronym => 'NCBI', :logo_cache_url => '921800', :homepage => 'http://www.ncbi.nlm.nih.gov/')


boa_agent = Agent.gen_if_not_exists(:full_name => 'Biology of Aging', :logo_cache_url => '318700')
boa_user = User.gen_if_not_exists(:display_name => 'Biology of Aging', :logo_cache_url => '318700', :agent => boa_agent)
boa_content_partner = ContentPartner.gen_if_not_exists(:user => boa_user, :full_name => "Biology of Aging")
boa_hierarchy = Hierarchy.gen_if_not_exists(:label => 'LigerCat',
                                   :description    => 'LigerCat Biomedical Terms Tag Cloud',
                                   :outlink_uri    => 'http://ligercat.ubio.org/eol/%%ID%%.cloud',
                                   :url            => 'http://ligercat.ubio.org',
                                   :agent_id => boa_agent.id)
boa_resource = Resource.gen_if_not_exists(:title => 'LigerCat resource', :content_partner => boa_content_partner)
links = CollectionType.gen_if_not_exists(:label => "Links")
lit   = CollectionType.gen_if_not_exists(:label => "Literature")
CollectionTypesHierarchy.gen(:hierarchy => boa_hierarchy, :collection_type => links)
CollectionTypesHierarchy.gen(:hierarchy => boa_hierarchy, :collection_type => lit)

AgentRole.gen_if_not_exists(:label => 'Author')
AgentRole.gen_if_not_exists(:label => 'Photographer')
AgentRole.gen_if_not_exists(:label => 'Contributor')
AgentRole.gen_if_not_exists(:label => 'Source')
AgentRole.gen_if_not_exists(:label => 'Source Database')

ContentPartnerStatus.gen_if_not_exists(:label => 'Active')
ContentPartnerStatus.gen_if_not_exists(:label => 'Archived')
ContentPartnerStatus.gen_if_not_exists(:label => 'Pending')

Audience.gen_if_not_exists(:label => 'Children')
Audience.gen_if_not_exists(:label => 'Expert users')
Audience.gen_if_not_exists(:label => 'General public')

DataType.create_defaults

LinkType.create_defaults

default_hierarchy = Hierarchy.gen_if_not_exists(:agent => Agent.catalogue_of_life, :label => $DEFAULT_HIERARCHY_NAME, :browsable => 1)
Hierarchy.gen_if_not_exists(:agent => Agent.catalogue_of_life, :label =>  "Species 2000 & ITIS Catalogue of Life: Annual Checklist 2007", :browsable => 0)
Hierarchy.gen_if_not_exists(:label => "Encyclopedia of Life Contributors")
first_ncbi = Hierarchy.gen_if_not_exists(:agent => Agent.ncbi, :label => "NCBI Taxonomy", :browsable => 1)
first_ncbi.hierarchy_group_id = 101
first_ncbi.hierarchy_group_version = 1
first_ncbi.save!
second_ncbi = Hierarchy.gen_if_not_exists(:agent => Agent.ncbi, :label => "NCBI Taxonomy", :browsable => 1)
second_ncbi.hierarchy_group_id = 101
second_ncbi.hierarchy_group_version = 2
second_ncbi.save!
Hierarchy.gen_if_not_exists(:agent => Agent.gen_if_not_exists(:full_name => 'GBIF'), :label => 'GBIF Nub Taxonomy', :browsable => 0)

Language.gen_if_not_exists(:label => 'English', :iso_639_1 => 'en', :source_form => 'English')
Language.gen_if_not_exists(:label => 'French', :iso_639_1 => 'fr', :iso_639_2 => 'fre', :source_form => 'Français') # Bootstrap uses this, tests i18n
Language.gen_if_not_exists(:label => 'Spanish', :iso_639_1 => 'es', :iso_639_2 => 'spa', :source_form => 'Español')
Language.gen_if_not_exists(:label => 'Arabic', :iso_639_1 => 'ar', :source_form => 'العربية') # For testing Arabic, obviously.
Language.gen_if_not_exists(:label => 'Chinese', :iso_639_1 => 'zh-hans', :source_form => '简体中文')
sci_name = Language.gen_if_not_exists(:label => 'Scientific Name', :iso_639_1 => '', :source_form => 'Scientific Name')
unknown  = Language.gen_if_not_exists(:label => 'Unknown', :iso_639_1 => '', :source_form => 'Unknown')

sci_name.update_attributes(:activated_on => nil)
unknown.update_attributes(:activated_on => nil)

License.create_defaults

MimeType.gen_if_not_exists(:label => 'image/jpeg')
MimeType.gen_if_not_exists(:label => 'audio/mpeg')
MimeType.gen_if_not_exists(:label => 'text/html')
MimeType.gen_if_not_exists(:label => 'text/plain')
MimeType.gen_if_not_exists(:label => 'video/x-flv')
MimeType.gen_if_not_exists(:label => 'video/quicktime')
MimeType.gen_if_not_exists(:label => 'audio/mpeg')
MimeType.gen_if_not_exists(:label => 'audio/x-wav')


# create_if_not_exists These don't exist yet, but will in the future:
# create_if_not_exists NormalizedQualifier :label => 'Name'
# create_if_not_exists NormalizedQualifier :label => 'Author'
# create_if_not_exists NormalizedQualifier :label => 'Year'

%w{kingdom phylum order class family genus species subspecies infraspecies variety form}.each do |rank|
  Rank.gen_if_not_exists(:label => rank)
end

ChangeableObjectType.create_defaults

RefIdentifierType.gen_if_not_exists(:label => 'url')
RefIdentifierType.gen_if_not_exists(:label => 'doi')

iucn_hierarchy = Hierarchy.gen_if_not_exists(:label => 'IUCN')
iucn_resource = Resource.gen_if_not_exists(:title => 'Initial IUCN Import', :hierarchy => iucn_hierarchy, :content_partner => iucn_content_parter, :acesspoint_url => "http://eol.org/api/ping.xml")
iucn_agent = Agent.iucn
raise "IUCN is nil" if iucn_agent.nil?
raise "IUCN Resource is nil" if iucn_resource.nil?

# This is out of order, of course, because it depends on the IUCN resource.
HarvestEvent.gen_if_not_exists(:resource_id => iucn_resource.id)

overview = TocItem.gen_if_not_exists(:label => 'Overview', :view_order => 1)
TocItem.gen_if_not_exists(:label => 'Brief Summary', :view_order => 2, :parent_id => overview.id)
TocItem.gen_if_not_exists(:label => 'Brief Description', :view_order => 2, :parent_id => overview.id)
TocItem.gen_if_not_exists(:label => 'Comprehensive Description', :view_order => 3, :toc_item => overview.id)
description = TocItem.gen_if_not_exists(:label => 'Description', :view_order => 4)
TocItem.gen_if_not_exists(:label => 'Nucleotide Sequences', :view_order => 5, :parent_id => description.id)
ecology_and_distribution = TocItem.gen_if_not_exists(:label => 'Ecology and Distribution', :view_order => 6)
TocItem.gen_if_not_exists(:label => 'Distribution', :view_order => 7, :parent_id => ecology_and_distribution.id)
wikipedia = TocItem.gen_if_not_exists(:label => 'Wikipedia', :view_order => 8)
TocItem.gen_if_not_exists(:label => 'Identification Resources', :view_order => 9, :parent_id => description.id)
#--
names_and_taxonomy = TocItem.gen_if_not_exists(:label => 'Names and Taxonomy', :view_order => 50)
TocItem.gen_if_not_exists(:label => 'Related Names', :view_order => 51, :parent_id => names_and_taxonomy.id)
TocItem.gen_if_not_exists(:label => 'Synonyms', :view_order => 52, :parent_id => names_and_taxonomy.id)
TocItem.gen_if_not_exists(:label => 'Common Names', :view_order => 53, :parent_id => names_and_taxonomy.id)
#--
page_stats = TocItem.gen_if_not_exists(:label => 'Page Statistics', :view_order => 57)
TocItem.gen_if_not_exists(:label => 'Content Summary', :view_order => 58, :parent_id => page_stats.id)
#--
TocItem.gen_if_not_exists(:label => 'Biodiversity Heritage Library', :view_order => 61)
ref_and_info = TocItem.gen_if_not_exists(:label => 'References and More Information', :view_order => 62)
#--
citizen_science = TocItem.gen_if_not_exists(:label => 'Citizen Science', :view_order => 70)
TocItem.gen_if_not_exists(:label => 'Citizen Science Links', :view_order => 71, :parent_id => citizen_science.id)


# Note that in all these "children", the view_order resets.  ...That reflects the real DB.
TocItem.gen_if_not_exists(:label => 'Literature References',  :view_order => 64, :parent_id => ref_and_info.id)
TocItem.gen_if_not_exists(:label => 'Content Partners',       :view_order => 65, :parent_id => ref_and_info.id)
TocItem.gen_if_not_exists(:label => 'Biomedical Terms',       :view_order => 66, :parent_id => ref_and_info.id)
TocItem.gen_if_not_exists(:label => 'Search the Web',         :view_order => 67, :parent_id => ref_and_info.id)
education = TocItem.gen_if_not_exists(:label => 'Education',  :view_order => 68)
TocItem.gen_if_not_exists(:label => 'Education Links',        :view_order => 69, :parent_id => education.id)
TocItem.gen_if_not_exists(:label => 'Education Resources',    :view_order => 70, :parent_id => education.id)

InfoItem.gen_if_not_exists(:schema_value => 'http://rs.tdwg.org/ontology/voc/SPMInfoItems#TaxonBiology',
  :label => 'TaxonBiology', :toc_item => TocItem.overview)
InfoItem.gen_if_not_exists(:schema_value => 'http://rs.tdwg.org/ontology/voc/SPMInfoItems#GeneralDescription',
  :label => 'GeneralDescription', :toc_item => description)
InfoItem.gen_if_not_exists(:schema_value => 'http://rs.tdwg.org/ontology/voc/SPMInfoItems#Distribution',
  :label => 'Distribution', :toc_item => ecology_and_distribution)
InfoItem.gen_if_not_exists(:schema_value => 'http://rs.tdwg.org/ontology/voc/SPMInfoItems#Habitat',
  :label => 'Habitat', :toc_item => ecology_and_distribution)
InfoItem.gen_if_not_exists(:schema_value => 'http://rs.tdwg.org/ontology/voc/SPMInfoItems#Morphology',
  :label => 'Morphology', :toc_item => description)
InfoItem.gen_if_not_exists(:schema_value => 'http://rs.tdwg.org/ontology/voc/SPMInfoItems#Conservation',
  :label => 'Conservation', :toc_item => description)
InfoItem.gen_if_not_exists(:schema_value => 'http://rs.tdwg.org/ontology/voc/SPMInfoItems#Uses',
  :label => 'Uses', :toc_item => description)
InfoItem.gen_if_not_exists(:schema_value => 'http://www.eol.org/voc/table_of_contents#Education',
  :label => 'Education', :toc_item => education)
InfoItem.gen_if_not_exists(:schema_value => 'http://www.eol.org/voc/table_of_contents#IdentificationResources',
  :label => 'IdentificationResources', :toc_item => description)
InfoItem.gen_if_not_exists(:schema_value => 'http://www.eol.org/voc/table_of_contents#Wikipedia',
  :label => 'Wikipedia', :toc_item => wikipedia)

ServiceType.gen_if_not_exists(:label => 'EOL Transfer Schema')

Status.gen_if_not_exists(:label => 'Inserted')
Status.gen_if_not_exists(:label => 'Unchanged')
Status.gen_if_not_exists(:label => 'Updated')

UntrustReason.gen_if_not_exists(:label => 'misidentified', :class_name => 'misidentified')
UntrustReason.gen_if_not_exists(:label => 'incorrect/misleading', :class_name => 'incorrect')
UntrustReason.gen_if_not_exists(:label => 'low quality', :class_name => 'poor')
UntrustReason.gen_if_not_exists(:label => 'duplicate', :class_name => 'duplicate')

Vetted.create_defaults

SynonymRelation.gen_if_not_exists(:label => "synonym")
SynonymRelation.gen_if_not_exists(:label => "common name")
SynonymRelation.gen_if_not_exists(:label => "genbank common name")

Visibility.create_defaults

ContentTable.create_details
NotificationFrequency.create_defaults
Permission.create_defaults

# The home-page doesn't render without random taxa.  Note that other scenarios, if they build legitimate RandomTaxa,
# will need to DELETE these before they make their own!  But for foundation's purposes, this is required:
RandomHierarchyImage.delete_all
d = DataObject.gen
he = HierarchyEntry.gen(:hierarchy => default_hierarchy)
DataObjectsHierarchyEntry.gen(:data_object => d, :hierarchy_entry => he, :vetted => Vetted.trusted, :visibility => Visibility.visible)
5.times { RandomHierarchyImage.gen(:hierarchy => default_hierarchy, :hierarchy_entry => he, :data_object => d) }

Rails.cache.clear # TODO - attempt removal; if tests still pass, leave it out. I think this is redundant.

$INDEX_RECORDS_IN_SOLR_ON_SAVE = original_index_records_on_save_value
