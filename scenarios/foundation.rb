# sets up a basic foundation - enough data to run the application, but no content

def create_if_not_exists(klass, attributes)
  begin
    klass.send(:gen, attributes)
  rescue ActiveRecord::RecordInvalid => e
    # create_if_not_exists Do nothing; we don't care.  This is (usually, we hope) caused when such a thing already exists.
  end
end

# create_if_not_exists This ensures the main menu is complete, with at least one (albeit bogus) item in each section:
create_if_not_exists ContentPage, :title => 'Home',           :language_abbr => 'en', :content_section => ContentSection.gen(:name => 'Home Page')
create_if_not_exists ContentPage, :title => 'Who We Are',     :language_abbr => 'en', :content_section => ContentSection.gen(:name => 'About EOL')
create_if_not_exists ContentPage, :title => 'Contact Us',     :language_abbr => 'en', :content_section => ContentSection.gen(:name => 'Feedback')
create_if_not_exists ContentPage, :title => 'Screencasts',    :language_abbr => 'en', :content_section => ContentSection.gen(:name => 'Using the Site')
create_if_not_exists ContentPage, :title => 'Press Releases', :language_abbr => 'en', :content_section => ContentSection.gen(:name => 'Press Room')
create_if_not_exists ContentPage, :title => 'Terms Of Use',   :language_abbr => 'en', :content_section => ContentSection.gen(:name => 'Footer')

create_if_not_exists CuratorActivity, :code => 'delete'
create_if_not_exists CuratorActivity, :code => 'update'

# create_if_not_exists We don't technically *need* all three of these, but it's nice to have for the menu.  There are more, but we don't currently use
# them.  create_if_not_exists Once we do, they should get added here.
create_if_not_exists AgentContactRole, :label => 'Primary Contact'
create_if_not_exists AgentContactRole, :label => 'Administrative Contact'
create_if_not_exists AgentContactRole, :label => 'Technical Contact'

create_if_not_exists Agent, :full_name => 'IUCN'
create_if_not_exists AgentContact, :agent => Agent.iucn, :agent_contact_role => AgentContactRole.primary
create_if_not_exists Agent, :full_name => 'Catalogue of Life'
create_if_not_exists AgentContact, :agent => Agent.catalogue_of_life, :agent_contact_role => AgentContactRole.primary

create_if_not_exists AgentDataType, :label => 'Audio'
create_if_not_exists AgentDataType, :label => 'Image'
create_if_not_exists AgentDataType, :label => 'Text'
create_if_not_exists AgentDataType, :label => 'Video'

create_if_not_exists AgentRole, :label => 'Animator'
create_if_not_exists AgentRole, :label => 'Author'
create_if_not_exists AgentRole, :label => 'Compiler'
create_if_not_exists AgentRole, :label => 'Composer'
create_if_not_exists AgentRole, :label => 'Creator'
create_if_not_exists AgentRole, :label => 'Director'
create_if_not_exists AgentRole, :label => 'Editor'
create_if_not_exists AgentRole, :label => 'Illustrator'
create_if_not_exists AgentRole, :label => 'Photographer'
create_if_not_exists AgentRole, :label => 'Project'
create_if_not_exists AgentRole, :label => 'Publisher'
create_if_not_exists AgentRole, :label => 'Recorder'
create_if_not_exists AgentRole, :label => 'Source'

create_if_not_exists AgentStatus, :label => 'Active'
create_if_not_exists AgentStatus, :label => 'Archived'
create_if_not_exists AgentStatus, :label => 'Pending'

create_if_not_exists Audience, :label => 'Children'
create_if_not_exists Audience, :label => 'Expert users'
create_if_not_exists Audience, :label => 'General public'

create_if_not_exists DataType, :label => 'Image',     :schema_value => 'http://purl.org/dc/dcmitype/StillImage'
create_if_not_exists DataType, :label => 'Sound',     :schema_value => 'http://purl.org/dc/dcmitype/Sound'
create_if_not_exists DataType, :label => 'Text',      :schema_value => 'http://purl.org/dc/dcmitype/Text'
create_if_not_exists DataType, :label => 'Video',     :schema_value => 'http://purl.org/dc/dcmitype/MovingImage'
create_if_not_exists DataType, :label => 'GBIF Image'
create_if_not_exists DataType, :label => 'IUCN'
create_if_not_exists DataType, :label => 'Flash'
create_if_not_exists DataType, :label => 'YouTube'


create_if_not_exists Hierarchy, :agent => Agent.catalogue_of_life, :label => "Species 2000 & ITIS Catalogue of Life: Annual Checklist 2007"
create_if_not_exists Hierarchy, :agent => Agent.catalogue_of_life, :label => "Species 2000 & ITIS Catalogue of Life: Annual Checklist 2008"

create_if_not_exists InfoItem, :schema_value => 'http://rs.tdwg.org/ontology/voc/SPMInfoItems#Associations',          :label => 'Associations'
create_if_not_exists InfoItem, :schema_value => 'http://rs.tdwg.org/ontology/voc/SPMInfoItems#Behaviour',             :label => 'Behaviour'
create_if_not_exists InfoItem, :schema_value => 'http://rs.tdwg.org/ontology/voc/SPMInfoItems#ConservationStatus',    :label => 'ConservationStatus'
create_if_not_exists InfoItem, :schema_value => 'http://rs.tdwg.org/ontology/voc/SPMInfoItems#Cyclicity',             :label => 'Cyclicity'
create_if_not_exists InfoItem, :schema_value => 'http://rs.tdwg.org/ontology/voc/SPMInfoItems#Cytology',              :label => 'Cytology'
create_if_not_exists InfoItem, :schema_value => 'http://rs.tdwg.org/ontology/voc/SPMInfoItems#DiagnosticDescription', :label => 'DiagnosticDescription'
create_if_not_exists InfoItem, :schema_value => 'http://rs.tdwg.org/ontology/voc/SPMInfoItems#Diseases',              :label => 'Diseases'
create_if_not_exists InfoItem, :schema_value => 'http://rs.tdwg.org/ontology/voc/SPMInfoItems#Dispersal',             :label => 'Dispersal'
create_if_not_exists InfoItem, :schema_value => 'http://rs.tdwg.org/ontology/voc/SPMInfoItems#Distribution',          :label => 'Distribution'
create_if_not_exists InfoItem, :schema_value => 'http://rs.tdwg.org/ontology/voc/SPMInfoItems#Evolution',             :label => 'Evolution'
create_if_not_exists InfoItem, :schema_value => 'http://rs.tdwg.org/ontology/voc/SPMInfoItems#GeneralDescription',    :label => 'GeneralDescription'
create_if_not_exists InfoItem, :schema_value => 'http://rs.tdwg.org/ontology/voc/SPMInfoItems#Genetics',              :label => 'Genetics'
create_if_not_exists InfoItem, :schema_value => 'http://rs.tdwg.org/ontology/voc/SPMInfoItems#Growth',                :label => 'Growth'
create_if_not_exists InfoItem, :schema_value => 'http://rs.tdwg.org/ontology/voc/SPMInfoItems#Habitat',               :label => 'Habitat'
create_if_not_exists InfoItem, :schema_value => 'http://rs.tdwg.org/ontology/voc/SPMInfoItems#Legislation',           :label => 'Legislation'
create_if_not_exists InfoItem, :schema_value => 'http://rs.tdwg.org/ontology/voc/SPMInfoItems#LifeCycle',             :label => 'LifeCycle'
create_if_not_exists InfoItem, :schema_value => 'http://rs.tdwg.org/ontology/voc/SPMInfoItems#LifeExpectancy',        :label => 'LifeExpectancy'
create_if_not_exists InfoItem, :schema_value => 'http://rs.tdwg.org/ontology/voc/SPMInfoItems#LookAlikes',            :label => 'LookAlikes'
create_if_not_exists InfoItem, :schema_value => 'http://rs.tdwg.org/ontology/voc/SPMInfoItems#Management',            :label => 'Management'
create_if_not_exists InfoItem, :schema_value => 'http://rs.tdwg.org/ontology/voc/SPMInfoItems#Migration',             :label => 'Migration'
create_if_not_exists InfoItem, :schema_value => 'http://rs.tdwg.org/ontology/voc/SPMInfoItems#MolecularBiology',      :label => 'MolecularBiology'
create_if_not_exists InfoItem, :schema_value => 'http://rs.tdwg.org/ontology/voc/SPMInfoItems#Morphology',            :label => 'Morphology'
create_if_not_exists InfoItem, :schema_value => 'http://rs.tdwg.org/ontology/voc/SPMInfoItems#Physiology',            :label => 'Physiology'
create_if_not_exists InfoItem, :schema_value => 'http://rs.tdwg.org/ontology/voc/SPMInfoItems#PopulationBiology',     :label => 'PopulationBiology'
create_if_not_exists InfoItem, :schema_value => 'http://rs.tdwg.org/ontology/voc/SPMInfoItems#Procedures',            :label => 'Procedures'
create_if_not_exists InfoItem, :schema_value => 'http://rs.tdwg.org/ontology/voc/SPMInfoItems#Reproduction',          :label => 'Reproduction'
create_if_not_exists InfoItem, :schema_value => 'http://rs.tdwg.org/ontology/voc/SPMInfoItems#RiskStatement',         :label => 'RiskStatement'
create_if_not_exists InfoItem, :schema_value => 'http://rs.tdwg.org/ontology/voc/SPMInfoItems#Size',                  :label => 'Size'
create_if_not_exists InfoItem, :schema_value => 'http://rs.tdwg.org/ontology/voc/SPMInfoItems#TaxonBiology',          :label => 'TaxonBiology'
create_if_not_exists InfoItem, :schema_value => 'http://rs.tdwg.org/ontology/voc/SPMInfoItems#Threats',               :label => 'Threats'
create_if_not_exists InfoItem, :schema_value => 'http://rs.tdwg.org/ontology/voc/SPMInfoItems#Trends',                :label => 'Trends'
create_if_not_exists InfoItem, :schema_value => 'http://rs.tdwg.org/ontology/voc/SPMInfoItems#TrophicStrategy',       :label => 'TrophicStrategy'
create_if_not_exists InfoItem, :schema_value => 'http://rs.tdwg.org/ontology/voc/SPMInfoItems#Uses',                  :label => 'Uses'

create_if_not_exists Language, :name => 'English', :iso_639_1 => 'en'
create_if_not_exists Language, :name => 'French',  :iso_639_1 => 'fr' # Technically not required, but nice to check translation file.
create_if_not_exists Language, :name => 'scient',  :iso_639_1 => 'en' # Technically, this needs to be ID 501.  ...But only for PHP's sake.

create_if_not_exists License, :title => 'public domain',       :description => 'No rights reserved'
create_if_not_exists License, :title => 'all rights reserved', :description => '&#169; All rights reserved'
create_if_not_exists License, :title => 'cc-by-nc 3.0',        :description => 'Some rights reserved',
             :source_url => 'http://creativecommons.org/licenses/by-nc/3.0/',    :logo_url => '/images/licenses/cc_by_nc_small.png'
create_if_not_exists License, :title => 'cc-by 3.0',           :description => 'Some rights reserved',
             :source_url => 'http://creativecommons.org/licenses/by/3.0/',       :logo_url => '/images/licenses/cc_by_small.png'
create_if_not_exists License, :title => 'cc-by-sa 3.0',        :description => 'Some rights reserved',
             :source_url => 'http://creativecommons.org/licenses/by-sa/3.0/',    :logo_url => '/images/licenses/cc_by_sa_small.png'
create_if_not_exists License, :title => 'cc-by-nc-sa 3.0',     :description => 'Some rights reserved',
             :source_url => 'http://creativecommons.org/licenses/by-nc-sa/3.0/', :logo_url => '/images/licenses/cc_by_nc_sa_small.png'
create_if_not_exists License, :title => 'gnu-fdl',             :description => 'Some rights reserved',
             :source_url => 'http://www.gnu.org/licenses/fdl.html',              :logo_url => '/images/licenses/gnu_fdl_small.png'
create_if_not_exists License, :title => 'gnu-gpl',             :description => 'Some rights reserved',
             :source_url => 'http://www.gnu.org/licenses/gpl.html',              :logo_url => '/images/licenses/gnu_fdl_small.png'
create_if_not_exists License, :title => 'no license',          :description => 'The material cannot be licensed'

create_if_not_exists MimeType, :label => 'audio/mpeg'
create_if_not_exists MimeType, :label => 'audio/x-ms-wma'
create_if_not_exists MimeType, :label => 'audio/x-pn-realaudio'
create_if_not_exists MimeType, :label => 'audio/x-realaudio'
create_if_not_exists MimeType, :label => 'audio/x-wav'
create_if_not_exists MimeType, :label => 'image/bmp'
create_if_not_exists MimeType, :label => 'image/gif'
create_if_not_exists MimeType, :label => 'image/jpeg'
create_if_not_exists MimeType, :label => 'image/png'
create_if_not_exists MimeType, :label => 'image/svg+xml'
create_if_not_exists MimeType, :label => 'image/tiff'
create_if_not_exists MimeType, :label => 'text/html'
create_if_not_exists MimeType, :label => 'text/plain'
create_if_not_exists MimeType, :label => 'text/richtext'
create_if_not_exists MimeType, :label => 'text/rtf'
create_if_not_exists MimeType, :label => 'text/xml'
create_if_not_exists MimeType, :label => 'video/mp4'
create_if_not_exists MimeType, :label => 'video/mpeg'
create_if_not_exists MimeType, :label => 'video/quicktime'
create_if_not_exists MimeType, :label => 'video/x-flv'
create_if_not_exists MimeType, :label => 'video/x-ms-wmv'

# create_if_not_exists These don't exist yet, but will in the future:
# create_if_not_exists NormalizedQualifier :label => 'Name'
# create_if_not_exists NormalizedQualifier :label => 'Author'
# create_if_not_exists NormalizedQualifier :label => 'Year'

create_if_not_exists RefIdentifierType, :label => 'bici'
create_if_not_exists RefIdentifierType, :label => 'coden'
create_if_not_exists RefIdentifierType, :label => 'doi'
create_if_not_exists RefIdentifierType, :label => 'eissn'
create_if_not_exists RefIdentifierType, :label => 'handle'
create_if_not_exists RefIdentifierType, :label => 'isbn'
create_if_not_exists RefIdentifierType, :label => 'issn'
create_if_not_exists RefIdentifierType, :label => 'lsid'
create_if_not_exists RefIdentifierType, :label => 'oclc'
create_if_not_exists RefIdentifierType, :label => 'sici'
create_if_not_exists RefIdentifierType, :label => 'url'
create_if_not_exists RefIdentifierType, :label => 'urn'

create_if_not_exists ResourceAgentRole, :label => 'Administrative'
create_if_not_exists ResourceAgentRole, :label => 'Data Administrator'
create_if_not_exists ResourceAgentRole, :label => 'Data Host'
create_if_not_exists ResourceAgentRole, :label => 'Data Supplier'
create_if_not_exists ResourceAgentRole, :label => 'System Administrator'
create_if_not_exists ResourceAgentRole, :label => 'Technical Host'

create_if_not_exists ResourceStatus, :label => 'Uploading'
create_if_not_exists ResourceStatus, :label => 'Uploaded'
create_if_not_exists ResourceStatus, :label => 'Upload Failed'
create_if_not_exists ResourceStatus, :label => 'Moved to Content Server'
create_if_not_exists ResourceStatus, :label => 'Validated'
create_if_not_exists ResourceStatus, :label => 'Validation Failed'
create_if_not_exists ResourceStatus, :label => 'Being Processed'
create_if_not_exists ResourceStatus, :label => 'Processed'
create_if_not_exists ResourceStatus, :label => 'Processing Failed'
create_if_not_exists ResourceStatus, :label => 'Published'

create_if_not_exists Role, :title => 'Curator'
create_if_not_exists Role, :title => 'Moderator'
create_if_not_exists Role, :title => 'Administrator'
create_if_not_exists Role, :title => 'Administrator - News Items'
create_if_not_exists Role, :title => 'Administrator - Comments and Tags'
create_if_not_exists Role, :title => 'Administrator - Web Users'
create_if_not_exists Role, :title => 'Administrator - Contact Us Submissions'
create_if_not_exists Role, :title => 'Administrator - Content Partners'
create_if_not_exists Role, :title => 'Administrator - Error Logs'
create_if_not_exists Role, :title => 'Administrator - Site CMS'
create_if_not_exists Role, :title => 'Administrator - Usage Reports'

create_if_not_exists TocItem, :label => 'Overview',                      :view_order => 1
create_if_not_exists TocItem, :label => 'Common Names',                  :view_order => 10
ref_and_info = create_if_not_exists TocItem, :label => 'References and More Information', :view_order => 9
create_if_not_exists TocItem, :label => 'Biodiversity Heritage Library', :view_order => 8,  :parent_id => ref_and_info.id
create_if_not_exists TocItem, :label => 'Specialist Projects',           :view_order => 10, :parent_id => ref_and_info.id
create_if_not_exists TocItem, :label => 'Search the Web',                :view_order => 14, :parent_id => ref_and_info.id

create_if_not_exists ServiceType, :label => 'EOL Transfer Schema'

create_if_not_exists Status, :label => 'Inserted'
create_if_not_exists Status, :label => 'Unchanged'
create_if_not_exists Status, :label => 'Updated'

create_if_not_exists Vetted, :label => 'Unknown'    # This really wants an ID of 0, but only for PHP stuff.
create_if_not_exists Vetted, :label => 'Untrusted'
create_if_not_exists Vetted, :label => 'Trusted'

create_if_not_exists Visibility, :label => 'Invisible'      # This really wants an ID of 0, but only for PHP stuff.
create_if_not_exists Visibility, :label => 'Visible'
create_if_not_exists Visibility, :label => 'Preview'
create_if_not_exists Visibility, :label => 'Inappropriate'
