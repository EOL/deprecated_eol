# sets up a basic foundation - enough data to run the application, but no content

# This ensures the main menu is complete, with at least one (albeit bogus) item in each section:
ContentPage.gen :page_name => 'Home',           :language_abbr => 'en', :content_section => ContentSection.gen(:name => 'Home Page')
ContentPage.gen :page_name => 'Who We Are',     :language_abbr => 'en', :content_section => ContentSection.gen(:name => 'About EOL')
ContentPage.gen :page_name => 'Contact Us',     :language_abbr => 'en', :content_section => ContentSection.gen(:name => 'Feedback')
ContentPage.gen :page_name => 'Screencasts',    :language_abbr => 'en', :content_section => ContentSection.gen(:name => 'Using the Site')
ContentPage.gen :page_name => 'Press Releases', :language_abbr => 'en', :content_section => ContentSection.gen(:name => 'Press Room')
ContentPage.gen :page_name => 'Terms Of Use',   :language_abbr => 'en', :content_section => ContentSection.gen(:name => 'Footer')

CuratorActivity.gen :code => 'delete'
CuratorActivity.gen :code => 'update'

# We don't technically *need* all three of these, but it's nice to have for the menu.  There are more, but we don't currently use
# them.  Once we do, they should get added here.
AgentContactRole.gen :label => 'Primary Contact'
AgentContactRole.gen :label => 'Administrative Contact'
AgentContactRole.gen :label => 'Technical Contact'

Agent.gen :full_name => 'IUCN'
AgentContact.gen :agent => Agent.iucn, :agent_contact_role => AgentContactRole.primary
Agent.gen :full_name => 'Catalogue of Life'
AgentContact.gen :agent => Agent.catalogue_of_life, :agent_contact_role => AgentContactRole.primary

AgentDataType.gen :label => 'Audio'
AgentDataType.gen :label => 'Image'
AgentDataType.gen :label => 'Text'
AgentDataType.gen :label => 'Video'

AgentRole.gen :label => 'Animator'
AgentRole.gen :label => 'Author'
AgentRole.gen :label => 'Compiler'
AgentRole.gen :label => 'Composer'
AgentRole.gen :label => 'Creator'
AgentRole.gen :label => 'Director'
AgentRole.gen :label => 'Editor'
AgentRole.gen :label => 'Illustrator'
AgentRole.gen :label => 'Photographer'
AgentRole.gen :label => 'Project'
AgentRole.gen :label => 'Publisher'
AgentRole.gen :label => 'Recorder'
AgentRole.gen :label => 'Source'

AgentStatus.gen :label => 'Active'
AgentStatus.gen :label => 'Archived'
AgentStatus.gen :label => 'Pending'

Audience.gen :label => 'Children'
Audience.gen :label => 'Expert users'
Audience.gen :label => 'General public'

DataType.gen :label => 'Image',     :schema_value => 'http://purl.org/dc/dcmitype/StillImage'
DataType.gen :label => 'Sound',     :schema_value => 'http://purl.org/dc/dcmitype/Sound'
DataType.gen :label => 'Text',      :schema_value => 'http://purl.org/dc/dcmitype/Text'
DataType.gen :label => 'Video',     :schema_value => 'http://purl.org/dc/dcmitype/MovingImage'
DataType.gen :label => 'GBIF Image'
DataType.gen :label => 'IUCN'
DataType.gen :label => 'Flash'
DataType.gen :label => 'YouTube'


Hierarchy.gen :agent => Agent.catalogue_of_life, :label => "Species 2000 & ITIS Catalogue of Life: Annual Checklist 2007"
Hierarchy.gen :agent => Agent.catalogue_of_life, :label => "Species 2000 & ITIS Catalogue of Life: Annual Checklist 2008"

InfoItem.gen :schema_value => 'http://rs.tdwg.org/ontology/voc/SPMInfoItems#Associations',          :label => 'Associations'
InfoItem.gen :schema_value => 'http://rs.tdwg.org/ontology/voc/SPMInfoItems#Behaviour',             :label => 'Behaviour'
InfoItem.gen :schema_value => 'http://rs.tdwg.org/ontology/voc/SPMInfoItems#ConservationStatus',    :label => 'ConservationStatus'
InfoItem.gen :schema_value => 'http://rs.tdwg.org/ontology/voc/SPMInfoItems#Cyclicity',             :label => 'Cyclicity'
InfoItem.gen :schema_value => 'http://rs.tdwg.org/ontology/voc/SPMInfoItems#Cytology',              :label => 'Cytology'
InfoItem.gen :schema_value => 'http://rs.tdwg.org/ontology/voc/SPMInfoItems#DiagnosticDescription', :label => 'DiagnosticDescription'
InfoItem.gen :schema_value => 'http://rs.tdwg.org/ontology/voc/SPMInfoItems#Diseases',              :label => 'Diseases'
InfoItem.gen :schema_value => 'http://rs.tdwg.org/ontology/voc/SPMInfoItems#Dispersal',             :label => 'Dispersal'
InfoItem.gen :schema_value => 'http://rs.tdwg.org/ontology/voc/SPMInfoItems#Distribution',          :label => 'Distribution'
InfoItem.gen :schema_value => 'http://rs.tdwg.org/ontology/voc/SPMInfoItems#Evolution',             :label => 'Evolution'
InfoItem.gen :schema_value => 'http://rs.tdwg.org/ontology/voc/SPMInfoItems#GeneralDescription',    :label => 'GeneralDescription'
InfoItem.gen :schema_value => 'http://rs.tdwg.org/ontology/voc/SPMInfoItems#Genetics',              :label => 'Genetics'
InfoItem.gen :schema_value => 'http://rs.tdwg.org/ontology/voc/SPMInfoItems#Growth',                :label => 'Growth'
InfoItem.gen :schema_value => 'http://rs.tdwg.org/ontology/voc/SPMInfoItems#Habitat',               :label => 'Habitat'
InfoItem.gen :schema_value => 'http://rs.tdwg.org/ontology/voc/SPMInfoItems#Legislation',           :label => 'Legislation'
InfoItem.gen :schema_value => 'http://rs.tdwg.org/ontology/voc/SPMInfoItems#LifeCycle',             :label => 'LifeCycle'
InfoItem.gen :schema_value => 'http://rs.tdwg.org/ontology/voc/SPMInfoItems#LifeExpectancy',        :label => 'LifeExpectancy'
InfoItem.gen :schema_value => 'http://rs.tdwg.org/ontology/voc/SPMInfoItems#LookAlikes',            :label => 'LookAlikes'
InfoItem.gen :schema_value => 'http://rs.tdwg.org/ontology/voc/SPMInfoItems#Management',            :label => 'Management'
InfoItem.gen :schema_value => 'http://rs.tdwg.org/ontology/voc/SPMInfoItems#Migration',             :label => 'Migration'
InfoItem.gen :schema_value => 'http://rs.tdwg.org/ontology/voc/SPMInfoItems#MolecularBiology',      :label => 'MolecularBiology'
InfoItem.gen :schema_value => 'http://rs.tdwg.org/ontology/voc/SPMInfoItems#Morphology',            :label => 'Morphology'
InfoItem.gen :schema_value => 'http://rs.tdwg.org/ontology/voc/SPMInfoItems#Physiology',            :label => 'Physiology'
InfoItem.gen :schema_value => 'http://rs.tdwg.org/ontology/voc/SPMInfoItems#PopulationBiology',     :label => 'PopulationBiology'
InfoItem.gen :schema_value => 'http://rs.tdwg.org/ontology/voc/SPMInfoItems#Procedures',            :label => 'Procedures'
InfoItem.gen :schema_value => 'http://rs.tdwg.org/ontology/voc/SPMInfoItems#Reproduction',          :label => 'Reproduction'
InfoItem.gen :schema_value => 'http://rs.tdwg.org/ontology/voc/SPMInfoItems#RiskStatement',         :label => 'RiskStatement'
InfoItem.gen :schema_value => 'http://rs.tdwg.org/ontology/voc/SPMInfoItems#Size',                  :label => 'Size'
InfoItem.gen :schema_value => 'http://rs.tdwg.org/ontology/voc/SPMInfoItems#TaxonBiology',          :label => 'TaxonBiology'
InfoItem.gen :schema_value => 'http://rs.tdwg.org/ontology/voc/SPMInfoItems#Threats',               :label => 'Threats'
InfoItem.gen :schema_value => 'http://rs.tdwg.org/ontology/voc/SPMInfoItems#Trends',                :label => 'Trends'
InfoItem.gen :schema_value => 'http://rs.tdwg.org/ontology/voc/SPMInfoItems#TrophicStrategy',       :label => 'TrophicStrategy'
InfoItem.gen :schema_value => 'http://rs.tdwg.org/ontology/voc/SPMInfoItems#Uses',                  :label => 'Uses'

Language.gen :name => 'English', :iso_639_1 => 'en'
Language.gen :name => 'French',  :iso_639_1 => 'fr' # Technically not required, but nice to check translation file.
Language.gen :name => 'scient',  :iso_639_1 => 'en' # Technically, this needs to be ID 501.  ...But only for PHP's sake.

License.gen :title => 'public domain',       :description => 'No rights reserved'
License.gen :title => 'all rights reserved', :description => '&#169; All rights reserved'
License.gen :title => 'cc-by-nc 3.0',        :description => 'Some rights reserved',
              :source_url => 'http://creativecommons.org/licenses/by-nc/3.0/',    :logo_url => '/images/licenses/cc_by_nc_small.png'
License.gen :title => 'cc-by 3.0',           :description => 'Some rights reserved',
              :source_url => 'http://creativecommons.org/licenses/by/3.0/',       :logo_url => '/images/licenses/cc_by_small.png'
License.gen :title => 'cc-by-sa 3.0',        :description => 'Some rights reserved',
              :source_url => 'http://creativecommons.org/licenses/by-sa/3.0/',    :logo_url => '/images/licenses/cc_by_sa_small.png'
License.gen :title => 'cc-by-nc-sa 3.0',     :description => 'Some rights reserved',
              :source_url => 'http://creativecommons.org/licenses/by-nc-sa/3.0/', :logo_url => '/images/licenses/cc_by_nc_sa_small.png'
License.gen :title => 'gnu-fdl',             :description => 'Some rights reserved',
              :source_url => 'http://www.gnu.org/licenses/fdl.html',              :logo_url => '/images/licenses/gnu_fdl_small.png'
License.gen :title => 'gnu-gpl',             :description => 'Some rights reserved',
              :source_url => 'http://www.gnu.org/licenses/gpl.html',              :logo_url => '/images/licenses/gnu_fdl_small.png'
License.gen :title => 'no license',          :description => 'The material cannot be licensed'

MimeType.gen :label => 'audio/mpeg'
MimeType.gen :label => 'audio/x-ms-wma'
MimeType.gen :label => 'audio/x-pn-realaudio'
MimeType.gen :label => 'audio/x-realaudio'
MimeType.gen :label => 'audio/x-wav'
MimeType.gen :label => 'image/bmp'
MimeType.gen :label => 'image/gif'
MimeType.gen :label => 'image/jpeg'
MimeType.gen :label => 'image/png'
MimeType.gen :label => 'image/svg+xml'
MimeType.gen :label => 'image/tiff'
MimeType.gen :label => 'text/html'
MimeType.gen :label => 'text/plain'
MimeType.gen :label => 'text/richtext'
MimeType.gen :label => 'text/rtf'
MimeType.gen :label => 'text/xml'
MimeType.gen :label => 'video/mp4'
MimeType.gen :label => 'video/mpeg'
MimeType.gen :label => 'video/quicktime'
MimeType.gen :label => 'video/x-flv'
MimeType.gen :label => 'video/x-ms-wmv'

# These don't exist yet, but will in the future:
# NormalizedQualifier :label => 'Name'
# NormalizedQualifier :label => 'Author'
# NormalizedQualifier :label => 'Year'

RefIdentifierType.gen :label => 'bici'
RefIdentifierType.gen :label => 'coden'
RefIdentifierType.gen :label => 'doi'
RefIdentifierType.gen :label => 'eissn'
RefIdentifierType.gen :label => 'handle'
RefIdentifierType.gen :label => 'isbn'
RefIdentifierType.gen :label => 'issn'
RefIdentifierType.gen :label => 'lsid'
RefIdentifierType.gen :label => 'oclc'
RefIdentifierType.gen :label => 'sici'
RefIdentifierType.gen :label => 'url'
RefIdentifierType.gen :label => 'urn'

ResourceAgentRole.gen :label => 'Administrative'
ResourceAgentRole.gen :label => 'Data Administrator'
ResourceAgentRole.gen :label => 'Data Host'
ResourceAgentRole.gen :label => 'Data Supplier'
ResourceAgentRole.gen :label => 'System Administrator'
ResourceAgentRole.gen :label => 'Technical Host'

ResourceStatus.gen :label => 'Uploading'
ResourceStatus.gen :label => 'Uploaded'
ResourceStatus.gen :label => 'Upload Failed'
ResourceStatus.gen :label => 'Moved to Content Server'
ResourceStatus.gen :label => 'Validated'
ResourceStatus.gen :label => 'Validation Failed'
ResourceStatus.gen :label => 'Being Processed'
ResourceStatus.gen :label => 'Processed'
ResourceStatus.gen :label => 'Processing Failed'
ResourceStatus.gen :label => 'Published'

Role.gen :title => 'Curator'
Role.gen :title => 'Moderator'
Role.gen :title => 'Administrator'
Role.gen :title => 'Administrator - News Items'
Role.gen :title => 'Administrator - Comments and Tags'
Role.gen :title => 'Administrator - Web Users'
Role.gen :title => 'Administrator - Contact Us Submissions'
Role.gen :title => 'Administrator - Content Partners'
Role.gen :title => 'Administrator - Error Logs'
Role.gen :title => 'Administrator - Site CMS'
Role.gen :title => 'Administrator - Usage Reports'

TocItem.gen :label => 'Overview',                      :view_order => 1
TocItem.gen :label => 'Common Names',                  :view_order => 10
ref_and_info = TocItem.gen :label => 'References and More Information', :view_order => 9
TocItem.gen :label => 'Biodiversity Heritage Library', :view_order => 8,  :parent_id => ref_and_info.id
TocItem.gen :label => 'Specialist Projects',           :view_order => 10, :parent_id => ref_and_info.id
TocItem.gen :label => 'Search the Web',                :view_order => 14, :parent_id => ref_and_info.id

ServiceType.gen :label => 'EOL Transfer Schema'

Status.gen :label => 'Inserted'
Status.gen :label => 'Unchanged'
Status.gen :label => 'Updated'

Vetted.gen :label => 'Unknown'    # This really wants an ID of 0, but only for PHP stuff.
Vetted.gen :label => 'Untrusted'
Vetted.gen :label => 'Trusted'

Visibility.gen :label => 'Invisible'      # This really wants an ID of 0, but only for PHP stuff.
Visibility.gen :label => 'Visible'
Visibility.gen :label => 'Preview'
Visibility.gen :label => 'Inappropriate'
