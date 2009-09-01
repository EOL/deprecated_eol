# sets up a basic foundation - enough data to run the application, but no content

# Use a factory to build an object that may already be there.  This syntax sucks, it would be nice to move this
# to the same place as ActiveRecord::Base#gen, which we're adding elsewhere...

def create_if_not_exists(klass, attributes)
  found = nil
  begin
    searchable_attributes = {}
    attributes.keys.each do |key|
      # Specified ids could be stored as Fixnum, not just int:
      if attributes[key].class == String or attributes[key].class == Integer or attributes[key].class == Fixnum or
         attributes[key].class == TrueClass or attributes[key].class == FalseClass
        searchable_attributes[key] = attributes[key]
      elsif attributes[key].class != Array
        key_id = "#{key}_id"
        key_id = 'toc_id' if key_id == 'toc_item_id'
        searchable_attributes[key_id] = attributes[key].id
      end
    end
    # Assumes that .keys returns in same order as .values, which is appears is true:
    begin
      found = klass.send("find_by_" << searchable_attributes.keys.join('_and_'), searchable_attributes.values) unless
        searchable_attributes.keys.blank?
    rescue NoMethodError
      raise "It seems there is a bad column on #{klass}. One of its expected attributes seems to be missing: " +
            "#{searchable_attributes.join(', ')}"
    end
    found = klass.send(:gen, attributes) if found.nil?
  rescue ActiveRecord::RecordInvalid => e
    puts "** Invalid Record : #{e.message}"
  rescue ActiveRecord::StatementInvalid => e
    raise e unless klass.name == "AgentsResource" # Okay, TOTAL hack.  But for some reason, this was the ONLY class
                                                  # For which the above find() method failed.  No clue why.  - JRice
  end
  return found
end

Rails.cache.clear # because we are resetting everything!  Sometimes, say, iucn is set.

# I AM NOT INDENTING THIS BLOCK (it seemed overkill)
if User.find_by_username('foundation_already_loaded').nil?

# This ensures the main menu is complete, with at least one (albeit bogus) item in each section:
create_if_not_exists ContentPage, :title => 'Home',
  :language_abbr => 'en', :content_section => ContentSection.gen(:name => 'Home Page')
create_if_not_exists ContentPage, :title => 'Who We Are',
  :language_abbr => 'en', :content_section => ContentSection.gen(:name => 'About EOL')
create_if_not_exists ContentPage, :title => 'Contact Us',
  :language_abbr => 'en', :content_section => ContentSection.gen(:name => 'Feedback')
create_if_not_exists ContentPage, :title => 'Screencasts',
  :language_abbr => 'en', :content_section => ContentSection.gen(:name => 'Using the Site')
create_if_not_exists ContentPage, :title => 'Press Releases',
  :language_abbr => 'en', :content_section => ContentSection.gen(:name => 'Press Room')
create_if_not_exists ContentPage, :title => 'Terms Of Use',
  :language_abbr => 'en', :content_section => ContentSection.gen(:name => 'Footer')

create_if_not_exists ContactSubject, :title => 'Media Contact', :recipients=>'test@test.com', :active=>true

create_if_not_exists CuratorActivity, :code => 'delete'
create_if_not_exists CuratorActivity, :code => 'update'
create_if_not_exists CuratorActivity, :code => 'show'
create_if_not_exists CuratorActivity, :code => 'hide'
create_if_not_exists CuratorActivity, :code => 'inappropriate'
create_if_not_exists CuratorActivity, :code => 'approve'
create_if_not_exists CuratorActivity, :code => 'disapprove'

# what one can do with a data_object
create_if_not_exists ActionWithObject, :action_code => 'create'
create_if_not_exists ActionWithObject, :action_code => 'update'     #?
create_if_not_exists ActionWithObject, :action_code => 'delete'
create_if_not_exists ActionWithObject, :action_code => 'trusted'
create_if_not_exists ActionWithObject, :action_code => 'untrusted'
create_if_not_exists ActionWithObject, :action_code => 'show'
create_if_not_exists ActionWithObject, :action_code => 'hide'
create_if_not_exists ActionWithObject, :action_code => 'inappropriate'

# create_if_not_exists We don't technically *need* all three of these, but it's nice to have for the menu.  There are more, but we don't currently use
# them.  create_if_not_exists Once we do, they should get added here.
create_if_not_exists AgentContactRole, :label => 'Primary Contact'
create_if_not_exists AgentContactRole, :label => 'Administrative Contact'
create_if_not_exists AgentContactRole, :label => 'Technical Contact'

create_if_not_exists Agent, :full_name => 'IUCN'
create_if_not_exists ContentPartner, :agent => Agent.iucn
create_if_not_exists AgentContact, :agent => Agent.iucn, :agent_contact_role => AgentContactRole.primary
create_if_not_exists Agent, :full_name => 'Catalogue of Life'
create_if_not_exists ContentPartner, :agent => Agent.catalogue_of_life
create_if_not_exists AgentContact, :agent => Agent.catalogue_of_life, :agent_contact_role => AgentContactRole.primary

boa_agent =
  create_if_not_exists Agent, :full_name => 'Biology of Aging'
liger_cat =
  create_if_not_exists Collection, :title          => 'LigerCat',
                                   :description    => 'LigerCat Biomedical Terms Tag Cloud',
                                   :uri            => 'http://ligercat.ubio.org/eol/FOREIGNKEY.cloud',
                                   :link           => 'http://ligercat.ubio.org',
                                   :logo_cache_url => '3187',
                                   :agent_id => boa_agent.id # Using id to make c_i_n_e work.
links = CollectionType.gen(:label => "Links")
lit   = CollectionType.gen(:label => "Literature")
CollectionTypesCollection.gen(:collection => liger_cat, :collection_type => links)
CollectionTypesCollection.gen(:collection => liger_cat, :collection_type => lit)

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
create_if_not_exists Hierarchy, :agent => Agent.catalogue_of_life, :label => "Species 2000 & ITIS Catalogue of Life: Annual Checklist 2008", :browsable => 1
default_hierarchy = create_if_not_exists Hierarchy, :agent => Agent.catalogue_of_life, :label => "Species 2000 & ITIS Catalogue of Life: Annual Checklist 2009"

create_if_not_exists InfoItem, :schema_value => 'http://rs.tdwg.org/ontology/voc/SPMInfoItems#Associations',          :label => 'Associations'
create_if_not_exists InfoItem, :schema_value => 'http://rs.tdwg.org/ontology/voc/SPMInfoItems#Behaviour',             :label => 'Behaviour'
create_if_not_exists InfoItem, :schema_value => 'http://rs.tdwg.org/ontology/voc/SPMInfoItems#ConservationStatus',    :label => 'ConservationStatus'
create_if_not_exists InfoItem, :schema_value => 'http://rs.tdwg.org/ontology/voc/SPMInfoItems#Cyclicity',             :label => 'Cyclicity'
create_if_not_exists InfoItem, :schema_value => 'http://rs.tdwg.org/ontology/voc/SPMInfoItems#Cytology',              :label => 'Cytology'
create_if_not_exists InfoItem, :schema_value => 'http://rs.tdwg.org/ontology/voc/SPMInfoItems#DiagnosticDescription', :label => 'DiagnosticDescription'
create_if_not_exists InfoItem, :schema_value => 'http://rs.tdwg.org/ontology/voc/SPMInfoItems#Diseases',              :label => 'Diseases'
create_if_not_exists InfoItem, :schema_value => 'http://rs.tdwg.org/ontology/voc/SPMInfoItems#Dispersal',             :label => 'Dispersal'
create_if_not_exists InfoItem, :schema_value => 'http://rs.tdwg.org/ontology/voc/SPMInfoItems#Evolution',             :label => 'Evolution'
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
create_if_not_exists InfoItem, :schema_value => 'http://rs.tdwg.org/ontology/voc/SPMInfoItems#Threats',               :label => 'Threats'
create_if_not_exists InfoItem, :schema_value => 'http://rs.tdwg.org/ontology/voc/SPMInfoItems#Trends',                :label => 'Trends'
create_if_not_exists InfoItem, :schema_value => 'http://rs.tdwg.org/ontology/voc/SPMInfoItems#TrophicStrategy',       :label => 'TrophicStrategy'
create_if_not_exists InfoItem, :schema_value => 'http://rs.tdwg.org/ontology/voc/SPMInfoItems#Uses',                  :label => 'Uses'

create_if_not_exists Language, :label => 'English',         :iso_639_1 => 'en'
create_if_not_exists Language, :label => 'French',          :iso_639_1 => 'fr' # Technically not required, but to test i18n
create_if_not_exists Language, :label => 'Scientific Name', :iso_639_1 => ''   # Should be ID 501.  ...But only for PHP's sake.

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

%w{kingdom phylum order class family genus species subspecies infraspecies variety form}.each do |rank|
  create_if_not_exists Rank, :label => rank
end

create_if_not_exists ChangeableObjectType, :ch_object_type => 'data_object'
create_if_not_exists ChangeableObjectType, :ch_object_type => 'comment'
create_if_not_exists ChangeableObjectType, :ch_object_type => 'tag'
create_if_not_exists ChangeableObjectType, :ch_object_type => 'users_submitted_text'

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

iucn_resource = create_if_not_exists Resource, :title => 'Initial IUCN Import'
create_if_not_exists AgentsResource, :resource => iucn_resource, :agent => Agent.iucn

# This is out of ourder, of course, because it depends on the IUCN resource.
create_if_not_exists HarvestEvent, :resource_id => Resource.iucn[0].id

create_if_not_exists ResourceAgentRole, :label => 'Administrative'
create_if_not_exists ResourceAgentRole, :label => 'Data Administrator'
create_if_not_exists ResourceAgentRole, :label => 'Data Host'
create_if_not_exists ResourceAgentRole, :label => 'Data Supplier'        # content_partner_upload_role
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
create_if_not_exists Role, :title => 'Administrator - Technical'
create_if_not_exists Role, :title => 'Administrator - Site CMS'
create_if_not_exists Role, :title => 'Administrator - Usage Reports'

create_if_not_exists TocItem, :label => 'Overview',                      :view_order => 1
description =
  create_if_not_exists TocItem, :label => 'Description',                   :view_order => 2
ecology_and_distribution =
  create_if_not_exists TocItem, :label => 'Ecology and Distribution',      :view_order => 3
create_if_not_exists TocItem, :label => 'Common Names',                  :view_order => 10
ref_and_info =
  create_if_not_exists TocItem, :label => 'References and More Information', :view_order => 9

# Note that in all these "children", the view_order resets.  ...That reflects the real DB.
create_if_not_exists TocItem, :label => 'Biodiversity Heritage Library', :view_order => 1, :parent_id => ref_and_info.id
create_if_not_exists TocItem, :label => 'Specialist Projects',           :view_order => 4, :parent_id => ref_and_info.id
create_if_not_exists TocItem, :label => 'Biomedical Terms',              :view_order => 8, :parent_id => ref_and_info.id
create_if_not_exists TocItem, :label => 'Search the Web',                :view_order => 12,:parent_id => ref_and_info.id
create_if_not_exists TocItem, :label => 'Literature References',         :view_order => 16,:parent_id => ref_and_info.id

create_if_not_exists InfoItem, :schema_value => 'http://rs.tdwg.org/ontology/voc/SPMInfoItems#TaxonBiology', :label => 'TaxonBiology', :toc_item => TocItem.overview
create_if_not_exists InfoItem, :schema_value => 'http://rs.tdwg.org/ontology/voc/SPMInfoItems#GeneralDescription', :label => 'GeneralDescription', :toc_item => description
create_if_not_exists InfoItem, :schema_value => 'http://rs.tdwg.org/ontology/voc/SPMInfoItems#Distribution', :label => 'Distribution', :toc_item => ecology_and_distribution

create_if_not_exists ServiceType, :label => 'EOL Transfer Schema'

create_if_not_exists Status, :label => 'Inserted'
create_if_not_exists Status, :label => 'Unchanged'
create_if_not_exists Status, :label => 'Updated'

create_if_not_exists UntrustReason, :label => 'Misidentified'
create_if_not_exists UntrustReason, :label => 'Incorrect'
create_if_not_exists UntrustReason, :label => 'Poor'
create_if_not_exists UntrustReason, :label => 'Duplicate'
create_if_not_exists UntrustReason, :label => 'Other'

create_if_not_exists Vetted, :label => 'Unknown'    # This really wants an ID of 0, but only for PHP stuff.
create_if_not_exists Vetted, :label => 'Untrusted'
create_if_not_exists Vetted, :label => 'Trusted'

create_if_not_exists Visibility, :label => 'Invisible'      # This really wants an ID of 0, but only for PHP stuff.
create_if_not_exists Visibility, :label => 'Visible'
create_if_not_exists Visibility, :label => 'Preview'
create_if_not_exists Visibility, :label => 'Inappropriate'

# The home-page doesn't render without random taxa.  Note that other scenarios, if they build legitimate RandomTaxa,
# will need to DELETE these before they make their own!  But for foundation's purposes, this is required:
RandomHierarchyImage.delete_all
10.times {  RandomHierarchyImage.gen(:hierarchy => default_hierarchy) }


# This prevents us from loading things twice, which it seems we were doing a lot!
User.gen :username => 'foundation_already_loaded'

else # THIS WAS NOT INDENTED.  It was an 'if' over almost the whole file, and didn't make sense to.
  puts "** WARNING: You attempted to load the foundation scenario twice, here.  Please fix it."
end # THIS WAS NOT INDENTED.  It was an 'if' over almost the whole file, and didn't make sense to.
