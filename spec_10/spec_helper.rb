# This file is copied to ~/spec when you run 'ruby script/generate rspec'
# from the project root directory.
ENV["RAILS_ENV"] = "test"
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
require File.expand_path(File.dirname(__FILE__) + "/valid_model_builder")
require 'spec'
require 'spec/rails'
# This is necessary to handle composite primary keys in fixtures:
load 'composite_primary_keys/fixtures.rb' 

# these will load up the test databases using the 
# development databases' schemas.  doesn't fix 
# transactions, tho.
#
# UseDbTest.prepare_test_db :suffix => "_data"
# UseDbTest.prepare_test_db :suffix => "_logging"

Spec::Runner.configure do |config|
  config.use_transactional_fixtures = true
  config.use_instantiated_fixtures  = false
  config.fixture_path = RAILS_ROOT + '/spec/fixtures/'

  # taken from use_db/lib/override_test_case.rb
  #
  # these before and after blocks make sure that spec 
  # examples run within their own transactions for ALL 
  # active connections (works for ALL of our databases)
  config.before(:each) do
    UseDbPlugin.all_use_dbs.collect do |klass|
      klass
    end

    ActiveRecord::Base.active_connections.values.uniq.each do |conn|
      Thread.current['open_transactions'] ||= 0
      Thread.current['open_transactions'] += 1
      conn.begin_db_transaction
    end
  end
  config.after(:each) do
    ActiveRecord::Base.active_connections.values.uniq.each do |conn|                  
      conn.rollback_db_transaction
      Thread.current['open_transactions'] = 0
    end
  end

  def mock_user
    user = mock_model(User)
    user.stub!(:id).and_return(100)
    user.stub!(:language).and_return(Language.english) # default language is english for new users
    user.stub!(:language_abbr).and_return('en')
    user.stub!(:expertise).and_return($DEFAULT_EXPERTISE)
    user.stub!(:remote_ip).and_return('128.0.0.1')
    user.stub!(:vetted).and_return($DEFAULT_VETTED)
    user.stub!(:mailing_list).and_return(true)
    user.stub!(:content_level).and_return($DEFAULT_CONTENT_LEVEL) # a number from 1-4, with 1 being all content and 4 being most restrictive
    user.stub!(:email).and_return("")
    user.stub!(:given_name).and_return("Mock")
    user.stub!(:family_name).and_return("User")
    user.stub!(:flash_enabled).and_return(true)
    user.stub!(:default_taxonomic_browser).and_return($DEFAULT_TAXONOMIC_BROWSER)
    user.stub!(:tags_for).and_return([])
    user.stub!(:tag_keys).and_return([])
    user.stub!(:is_admin?).and_return(false)
    user.stub!(:is_curator?).and_return(false)
    user.stub!(:can_curate?).and_return(false)
    user.stub!(:show_unvetted?).and_return(false)
    user.stub!(:comments).and_return([])
    return user
  end

end

# quite down any migrations that run during tests
ActiveRecord::Migration.verbose = false

# shortcut / helper for easily creating dates from a string
#   date = D['01/15/2008']
D = lambda { |str| Date.parse str } unless defined? D

# used in some of the different curation specs to get a data object in a particular clade
def create_dataobject_in_clade clade, object = nil
  clade = clade.id if clade.is_a?HierarchyEntry
  object = DataObject.first if object.nil?
  begin
    TopImage.create! :hierarchy_entry_id => clade, :data_object_id => object.id, :view_order => 1
  rescue Exception => ex
    # puts "TopImage.create failed: #{ ex.message }"
  end
  object
end

# helper for creating DataObjectLog objects with different data (which we can then Mine)
#
# can't use fixtures easily from spec_helper so :user tries to get User.find :first
#
# at the moment, this requires :data_objects and :data_types fixtures
#
# TODO this is misleading ... you would think that all of the options get passed 
#      to DataObjectLog#create, but they don't.  fix this!
#
# TODO - this might not be used anymore!  DEPRECIATE!!!!
def create_data_object_log options = {}
  options = {
    :state    => 'AZ',
    :country  => 'US',
    :user     => User.find(:first),
    :ip       => '4.3.2.1',
    :date     => '01/15/2008',
    :agent_id => 1,
    :user_agent   => 'Mozilla/5.0 Firefox'
  }.merge(options)

  object = DataObject.find :first

  ip = IpAddress.create :number => IpAddress.ip2int(options[:ip]), :country_code => options[:country], :success => true,
                        :state => options[:state], :latitude => 33.7788, :longitude => 117.959, :provider => 'test'

  DataObjectLog.create :user_id => options[:user].id, :user_agent => options[:user_agent], :created_at => D[options[:date]],
                       :ip_address => ip, :data_object => object, :data_type_id => object.data_type_id, :agent_id => options[:agent_id]
end

#
# Custom Assertions
#

class IncludeIdOf
  
  def initialize(match)
    @match = match.id
  end
  
  def matches?(results)
    @results = results # for use in messages
    return @results.any? {|r| (not r.nil?) and r.id == @match }
  end
  
  def description
    "include ID #{@match}"
  end
  
  def failure_message
    " expected to include a member with ID #{@match}, but none of the #{@results.length} results matched:\nRESULT IDS: #{@results.collect {|r| r.id}.join(', ')}"
  end
  
  def negative_failure_message
    " expected to have no members matching ID #{@match}, but did."
  end
end

def include_id_of(match)
  IncludeIdOf.new(match)
end

class ShareAttributesWith
  
  def initialize(match)
    @match = match
  end
  
  def matches?(comparitor)
    match = true
    comparitor.attributes.each do |attribute|
      next if attribute = 'id'
      unless comparitor[attribute] === @match[attribute]
        match = false
        break
      end
    end
    return match
  end
  
  def description
    "match the attributes of #{@match}"
  end
  
  def failure_message
    " expected to match the attributes of #{@match}, but didn't"
  end
  
  def negative_failure_message
    " expected not to match the attributes of #{@match}, but did."
  end
end

def share_attributes_with(match)
  ShareAttributesWith.new(match)
end

# This may look like a long an superflous method.  But it saves us OODLES of time running specs by avoiding the call to "fixtures
# :all) that we once had.  It's actually an astounding performance difference.  Sorry for the mess, though!
# TODO - low priority - this is not entirely fleshed out... I only covered those things Controllers really wanted.
def mock_cafeteria_concept(use_should = true)
  cafeteria_concept = mock_model(TaxonConcept)
  cafeteria_concept.stub!(:current_user=)
  cafeteria_concept.stub!(:name).and_return('<i>Cafeteria roenbergensis</i>')
  cafeteria_concept.stub!(:name).with(:expert, Language.english).and_return('<i>Cafeteria roenbergensis</i> Fenchel & D.J. Patterson')
  cafeteria_concept.stub!(:name).with(:natural_form).and_return('Cafeteria roenbergensis Fenchel & D.J. Patterson')
  cafeteria_concept.stub!(:has_name?).and_return(true)
  cafeteria_concept.stub!(:common_name).and_return('<i>Cafeteria roenbergensis</i>')
  cafeteria_concept.stub!(:scientific_name).and_return('<i>Cafeteria roenbergensis</i> Fenchel & D.J. Patterson')
  cafeteria_concept.stub!(:canonical_form).and_return('Cafeteria roenbergensis')
  cafeteria_concept.stub!(:ping_host_urls).and_return([])
  cafeteria_concept.stub!(:vernacular).and_return('<i>Cafeteria roenbergensis</i>')
  cafeteria_concept.stub!(:approved_curators).and_return([mock_user])
  canon = mock_model(CanonicalForm)
  canon.stub!(:string).and_return('Cafeteria roenbergensis')
  name = mock_model(Name)
  name.stub!(:string).and_return("Cafeteria roenbergensis Fenchel & D.J. Patterson")
  name.stub!(:italicized).and_return("<i>Cafeteria roenbergensis</i> Fenchel & D.J. Patterson")
  name.stub!(:canonical_form).and_return(canon)
  tcnames = [mock_model(TaxonConceptName), mock_model(TaxonConceptName)]
  tcnames[0].stub!(:name).and_return(name)
  tcnames[1].stub!(:name).and_return(name)
  cafeteria_concept.stub!(:taxon_concept_names).and_return(tcnames)
  cafeteria_concept.stub!(:content_level).and_return(4)
  cafeteria_concept.stub!(:has_citation?).and_return(false)
  cafeteria_concept.stub!(:available_media).and_return({:images=>true, :video=>true, :map=>true})
  cafeteria_concept.stub!(:more_images).and_return(false)
  cafeteria_concept.stub!(:more_videos).and_return(false)
  cafeteria_concept.stub!(:videos).and_return(mock_videos)
  cafeteria_concept.stub!(:map).and_return(DataObject.new(
    :data_type_id => 6,
    :mime_type_id => 9,
    :object_title => "",
    :language_id => 0,
    :license_id => 0,
    :rights_statement => "",
    :rights_holder => "",
    :bibliographic_citation => "",
    :source_url => "http://data.gbif.org/species/11484694",
    :description => "",
    :object_url => 'http://data.gbif.org/species/11484694/overviewMap.png',
    :object_cache_url => 2008102401123456,
    :thumbnail_url => "",
    :thumbnail_cache_url => "",
    :location => "",
    :latitude => 0.0,
    :longitude => 0.0,
    :altitude => 0.0,
    :object_created_at => nil,
    :object_modified_at => nil,
    :created_at => nil,
    :updated_at => "2008-02-04 00:00:00",
    :data_rating => 9999.0,
    :vetted_id => 2,
    :visibility_id => 1))
  cafeteria_concept.stub!(:iucn_conservation_status).and_return('SAMPLE CAFETERIA STATUS')
  cafeteria_concept.stub!(:iucn_conservation_status_url).and_return('http://www.iucn.org/')
  cafeteria_concept.stub!(:classification).and_return(<<EOXML)
<results>
  <ancestry>
		<node>
			<taxonID>16101659</taxonID>
			<nameString>Chromista</nameString>
			<rankName>Kingdom</rankName>
			<valid>true</valid>
			<enable>true</enable>
		</node>
		<node>
			<taxonID>16101973</taxonID>
			<nameString>&lt;i&gt;Sagenista&lt;/i&gt;</nameString>
			<rankName>Phylum</rankName>
			<valid>true</valid>
			<enable>true</enable>
		</node>
		<node>
			<taxonID>16101974</taxonID>
			<nameString>Bicosoecids</nameString>
			<rankName>Class</rankName>
			<valid>true</valid>
			<enable>true</enable>
		</node>
		<node>
			<taxonID>16101975</taxonID>
			<nameString>&lt;i&gt;Bicosoecales&lt;/i&gt;</nameString>
			<rankName>Order</rankName>
			<valid>true</valid>
			<enable>true</enable>
		</node>
		<node>
			<taxonID>16101978</taxonID>
			<nameString>&lt;i&gt;Cafeteriaceae&lt;/i&gt;</nameString>
			<rankName>Family</rankName>
			<valid>true</valid>
			<enable>true</enable>
		</node>
		<node>
			<taxonID>16109089</taxonID>
			<nameString>&lt;i&gt;Cafeteria&lt;/i&gt;</nameString>
			<rankName>Genus</rankName>
			<valid>true</valid>
			<enable>true</enable>
		</node>
	</ancestry>
	<current>
		<node>
			<taxonID>16222828</taxonID>
			<nameString>&lt;i&gt;Cafeteria roenbergensis&lt;/i&gt;</nameString>
			<rankName>Species</rankName>
			<valid>true</valid>
			<enable>true</enable>
		</node>
	</current>
	<kingdoms>
		<node>
			<taxonID>16097869</taxonID>
			<nameString>Animals</nameString>
			<rankName>Kingdom</rankName>
			<valid>true</valid>
			<enable>true</enable>
		</node>
		<node>
			<taxonID>16106613</taxonID>
			<nameString>Archaea</nameString>
			<rankName>Kingdom</rankName>
			<valid>true</valid>
			<enable>true</enable>
		</node>
		<node>
			<taxonID>16098245</taxonID>
			<nameString>Bacteria</nameString>
			<rankName>Kingdom</rankName>
			<valid>true</valid>
			<enable>true</enable>
		</node>
		<node>
			<taxonID>16101659</taxonID>
			<nameString>Chromista</nameString>
			<rankName>Kingdom</rankName>
			<valid>true</valid>
			<enable>true</enable>
		</node>
		<node>
			<taxonID>16101981</taxonID>
			<nameString>Fungi</nameString>
			<rankName>Kingdom</rankName>
			<valid>true</valid>
			<enable>true</enable>
		</node>
		<node>
			<taxonID>16098238</taxonID>
			<nameString>Plants</nameString>
			<rankName>Kingdom</rankName>
			<valid>true</valid>
			<enable>true</enable>
		</node>
		<node>
			<taxonID>16103012</taxonID>
			<nameString>Protozoa</nameString>
			<rankName>Kingdom</rankName>
			<valid>true</valid>
			<enable>true</enable>
		</node>
		<node>
			<taxonID>16103368</taxonID>
			<nameString>Viruses</nameString>
			<rankName>Kingdom</rankName>
			<valid>true</valid>
			<enable>true</enable>
		</node>
	</kingdoms>
	<attribution>
		<agent>
			<agentName>Species 2000 &amp; ITIS Catalogue of Life: 2007 Annual Checklist</agentName>
			<agentHomepage>http://www.catalogueoflife.org/</agentHomepage>
			<icon>colp.png</icon>
			<smallIcon>colp_small.png</smallIcon>
		</agent>
		<agent>
			<agentName></agentName>
			<agentHomepage>http://www.catalogueoflife.org/</agentHomepage>
			<icon></icon>
			<smallIcon></smallIcon>
		</agent>
	</attribution>
</results>
EOXML
  ancestry_hes = []
  common_names = %w(Chromista Sagenista Bicosoecids Bicosoecales Cafeteriaceae Cafeteria Cafeteria_roenbergensis_Fenchel_&_D.J._Patterson)
  sci_names    = %w(Chromista Sagenista Bicosoecophyceae Bicosoecales Cafeteriaceae Cafeteria Cafeteria_roenbergensis_Fenchel_&_D.J._Patterson)
  common_names.each_with_index do |common_name, index|
    ancestry_hes << mock_hierarchy_entry(common_name.gsub(/_/, ' '), sci_names[index].gsub(/_/, ' '),
                                         :taxon_concept_id => cafeteria_concept.id)
  end
  cafeteria_concept.stub!(:ancestry).and_return(ancestry_hes)
  cafeteria_concept.stub!(:entry).and_return(ancestry_hes[-1])
  cafeteria_concept.stub!(:hierarchy_entries).and_return([ancestry_hes[-1]])
  cafeteria_concept.stub!(:col_entry).and_return(ancestry_hes[-1])
  cafeteria_concept.stub!(:kingdom).and_return(ancestry_hes[0])
  cafeteria_concept.stub!(:children).and_return([])
  classification_attribution = [Agent.catalogue_of_life]
  classification_attribution.first.full_name = 'Species 2000 & ITIS Catalogue of Life: 2008 Annual Checklist'
  classification_attribution.first.display_name = 'Species 2000 & ITIS Catalogue of Life: 2008 Annual Checklist'
  cafeteria_concept.stub!(:classification_attribution).and_return(classification_attribution)
  toc = [mock_simple_toc_item("Overview"), mock_simple_toc_item("Description"), mock_simple_toc_item("Succinct"), mock_simple_toc_item("Diagnosis of genus and species"), mock_simple_toc_item("Formal Description"), mock_simple_toc_item("Molecular Biology and Genetics"), mock_simple_toc_item("Etymology"), mock_simple_toc_item("Description of Rootlets"), mock_simple_toc_item("Ecology and Distribution"), mock_simple_toc_item("Distribution"), mock_simple_toc_item("Microbial Food Web"), mock_simple_toc_item("Autecology"), mock_simple_toc_item("Evolution and Systematics"), mock_simple_toc_item("Phylogeny"), mock_simple_toc_item("Higher Level Affiliations"), mock_simple_toc_item("References and More Information"), mock_simple_toc_item("Literature References"), mock_simple_toc_item("Editor's Links"), mock_simple_toc_item("Specialist Projects"), mock_simple_toc_item("Search the Web")]
  cafeteria_concept.stub!(:table_of_contents).and_return(toc)
  cafeteria_concept.stub!(:content_by_category).with(toc[0].id).and_return({:category_name=>"Overview", :content_type=>"text",
                                                                    :data_objects=>[mock_overview]})
  cafeteria_concept.stub!(:images).and_return(big_list_of_images(cafeteria_concept.id, cafeteria_concept.name))
  cafeteria_concept.stub!(:title).and_return('<i>Cafeteria roenbergensis</i>')
  cafeteria_concept.stub!(:subtitle).and_return('<i>Cafeteria roenbergensis</i>')
  cafeteria_concept.stub!(:iucn).and_return(DataObject.new(
    :data_type_id => 5,
    :mime_type_id => 8,
    :object_title => "",
    :language_id => 0,
    :license_id => 6,
    :rights_statement => "",
    :rights_holder => "",
    :bibliographic_citation => "",
    :source_url => "",
    :description => "SAMPLE CAFETERIA STATUS",
    :object_url => "",
    :object_cache_url => 2008102401123457,
    :thumbnail_url => "",
    :thumbnail_cache_url => "",
    :location => "",
    :latitude => 0.0,
    :longitude => 0.0,
    :altitude => 0.0,
    :object_created_at => nil,
    :object_modified_at => nil,
    :created_at => nil,
    :updated_at => "2008-01-29 22:00:00",
    :data_rating => 0.5,
    :vetted_id => 2,
    :visibility_id => 1))
  cafeteria_concept.stub!(:smart_thumb).and_return()
  cafeteria_concept.stub!(:smart_medium_thumb).and_return()
  cafeteria_concept.stub!(:smart_image).and_return()
  cafeteria_concept.stub!(:<=>).and_return(0)
  cafeteria_concept.stub!(:xml_for_group).and_return()
  cafeteria_concept.stub!(:common_names).and_return()
  cafeteria_concept.stub!(:specialist_projects).and_return()
  cafeteria_concept.stub!(:biodiversity_heritage_library).and_return()
  cafeteria_concept.stub!(:catalogue_of_life_synonyms).and_return()
  cafeteria_concept.stub!(:get_default_content).and_return()
  default_hierarchy = mock_model(Hierarchy)
  kingdom_hes  = []
  sci_kings    = %w(Animalia Archaea Bacteria Chromista Fungi Plantae Protozoa Viruses)
  common_kings = %w(Animals Archaea Bacteria Chromista Fungi Plants Protozoa Viruses)
  common_kings.each_with_index do |common_name, index|
    if common_name == 'Chromista'
      kingdom_hes << ancestry_hes[0] # We built this one already
      next
    end
    kingdom_hes << mock_hierarchy_entry(common_name, sci_kings[index],
                                        :taxon_concept_id => cafeteria_concept.id)
  end
  default_hierarchy.stub!(:kingdoms).and_return(kingdom_hes)
  default_hierarchy.stub!(:kingdoms_hash).and_return([])
  Hierarchy.stub!(:default).at_least(1).times.and_return(default_hierarchy)
  DataObjectLog.stub!(:log).and_return([])
  return cafeteria_concept
end

def mock_simple_toc_item(label, child = false)
  titem = mock_model(TocItem)
  titem.stub!(:has_content?).and_return(true) # Doesn't matter for us...
  titem.stub!(:label).and_return(label)
  titem.stub!(:vetted_id).and_return(Vetted.trusted.id)
  titem.stub!(:is_child?).and_return(child)
  return titem
end

def big_list_of_images(our_id, name)
  big_list = [
    DataObject.new(:guid => "", :data_type_id => 5, :mime_type_id => 8, :object_title => "", :language_id => 0, :license_id => 6, :rights_statement => "", :rights_holder => "", :bibliographic_citation => "", :source_url => "", :description => "Scientific illustration", :object_url => "", :object_cache_url => 200810240123456, :thumbnail_url => "", :thumbnail_cache_url => "", :location => "", :latitude => 0.0, :longitude => 0.0, :altitude => 0.0, :object_created_at => nil, :object_modified_at => nil, :created_at => nil, :updated_at => "2008-01-29 22:00:00", :data_rating => 0.5, :vetted_id => 2, :visibility_id => 1),
    DataObject.new(:guid => "", :data_type_id => 5, :mime_type_id => 8, :object_title => "", :language_id => 0, :license_id => 3, :rights_statement => "", :rights_holder => "", :bibliographic_citation => "", :source_url => "http://starcentral.mbl.edu/microscope/portal.php?pa...", :description => "Eutree - voucher materials", :object_url => "http://starcentral.mbl.edu/msr/rawdata/viewable/caf...", :object_cache_url => 200810240123457, :thumbnail_url => "", :thumbnail_cache_url => "", :location => "", :latitude => 0.0, :longitude => 0.0, :altitude => 0.0, :object_created_at => nil, :object_modified_at => nil, :created_at => nil, :updated_at => "2008-02-12 22:00:00", :data_rating => 1.0, :vetted_id => 2, :visibility_id => 1),
    DataObject.new(:guid => "", :data_type_id => 5, :mime_type_id => 8, :object_title => "", :language_id => 0, :license_id => 3, :rights_statement => "", :rights_holder => "", :bibliographic_citation => "", :source_url => "http://starcentral.mbl.edu/microscope/portal.php?pa...", :description => "Plum Island, :Massachusetts coast, :USA", :object_url => "http://starcentral.mbl.edu/msr/rawdata/viewable/caf...", :object_cache_url => 200810240123458, :thumbnail_url => "", :thumbnail_cache_url => "", :location => "", :latitude => 0.0, :longitude => 0.0, :altitude => 0.0, :object_created_at => nil, :object_modified_at => nil, :created_at => nil, :updated_at => "2008-02-12 22:00:00", :data_rating => 2.0, :vetted_id => 2, :visibility_id => 1),
    DataObject.new(:guid => "", :data_type_id => 5, :mime_type_id => 8, :object_title => "", :language_id => 0, :license_id => 3, :rights_statement => "", :rights_holder => "", :bibliographic_citation => "", :source_url => "http://starcentral.mbl.edu/microscope/portal.php?pa...", :description => "Heterotrophic flagellates of Botany Bay, :Sydney, :Au...", :object_url => "http://starcentral.mbl.edu/msr/rawdata/viewable/caf...", :object_cache_url => 200810240123459, :thumbnail_url => "", :thumbnail_cache_url => "", :location => "", :latitude => 0.0, :longitude => 0.0, :altitude => 0.0, :object_created_at => nil, :object_modified_at => nil, :created_at => nil, :updated_at => "2008-02-12 22:00:00", :data_rating => 3.0, :vetted_id => 2, :visibility_id => 1),
    DataObject.new(:guid => "", :data_type_id => 5, :mime_type_id => 8, :object_title => "", :language_id => 0, :license_id => 3, :rights_statement => "", :rights_holder => "", :bibliographic_citation => "", :source_url => "http://starcentral.mbl.edu/microscope/portal.php?pa...", :description => "Protsville", :object_url => "http://starcentral.mbl.edu/msr/rawdata/viewable/caf...", :object_cache_url => 200810240123460, :thumbnail_url => "", :thumbnail_cache_url => "", :location => "", :latitude => 0.0, :longitude => 0.0, :altitude => 0.0, :object_created_at => nil, :object_modified_at => nil, :created_at => nil, :updated_at => "2008-02-12 22:00:00", :data_rating => 4.0, :vetted_id => 2, :visibility_id => 1),
    DataObject.new(:guid => "", :data_type_id => 5, :mime_type_id => 8, :object_title => "", :language_id => 0, :license_id => 3, :rights_statement => "", :rights_holder => "", :bibliographic_citation => "", :source_url => "http://starcentral.mbl.edu/microscope/portal.php?pa...", :description => "Heterotrophic flagellates of marine habitats", :object_url => "http://starcentral.mbl.edu/msr/rawdata/viewable/caf...", :object_cache_url => 200810240123461, :thumbnail_url => "", :thumbnail_cache_url => "", :location => "", :latitude => 0.0, :longitude => 0.0, :altitude => 0.0, :object_created_at => nil, :object_modified_at => nil, :created_at => nil, :updated_at => "2008-02-12 22:00:00", :data_rating => 5.0, :vetted_id => 2, :visibility_id => 1),
    DataObject.new(:guid => "", :data_type_id => 5, :mime_type_id => 8, :object_title => "", :language_id => 0, :license_id => 3, :rights_statement => "", :rights_holder => "", :bibliographic_citation => "", :source_url => "http://starcentral.mbl.edu/microscope/portal.php?pa...", :description => "Eel Pond, :Woods Hole, :Massachusetts", :object_url => "http://starcentral.mbl.edu/msr/rawdata/viewable/caf...", :object_cache_url => 200810240123462, :thumbnail_url => "", :thumbnail_cache_url => "", :location => "", :latitude => 0.0, :longitude => 0.0, :altitude => 0.0, :object_created_at => nil, :object_modified_at => nil, :created_at => nil, :updated_at => "2008-02-12 22:00:00", :data_rating => 6.0, :vetted_id => 2, :visibility_id => 1),
    DataObject.new(:guid => "", :data_type_id => 5, :mime_type_id => 8, :object_title => "", :language_id => 0, :license_id => 3, :rights_statement => "", :rights_holder => "", :bibliographic_citation => "", :source_url => "http://starcentral.mbl.edu/microscope/portal.php?pa...", :description => "Prawn Farm, :Queensland, :Australia", :object_url => "http://starcentral.mbl.edu/msr/rawdata/viewable/caf...", :object_cache_url => 200810240123463, :thumbnail_url => "", :thumbnail_cache_url => "", :location => "", :latitude => 0.0, :longitude => 0.0, :altitude => 0.0, :object_created_at => nil, :object_modified_at => nil, :created_at => nil, :updated_at => "2008-02-12 22:00:00", :data_rating => 100.0, :vetted_id => 2, :visibility_id => 1)]
  source = mock_model(Agent)
  source.stub!(:full_name).and_return('Eden Art')
  source.stub!(:homepage).and_return('http://www.tamaraclark.com/')
  source.stub!(:logo_cache_url).and_return(nil)
  source.stub!('ping_host?').and_return(false)
  author = mock_model(Agent)
  author.stub!('ping_host?').and_return(false)
  author.stub!(:full_name).and_return('Tamara Clark')
  author.stub!(:homepage).and_return('')
  author.stub!(:logo_cache_url).and_return(nil)
  big_list.each do |img|
    img[:taxon_id] = our_id.to_s
    img[:scientific_name] = name
    img[:license_text] = 'Some rights reserved'
    img[:license_url]  = 'http://creativecommons.org/licenses/by-nc-sa/3.0/'
    img[:license_logo] = '/images/licenses/cc_by_nc_sa_small.png'
    img.stub!(:authors).and_return(author)
    img.stub!(:sources).and_return(source)
  end
end

def mock_overview
  overview = mock_model(DataObject)
  overview.stub!(:visible_comments).and_return([])
  overview.stub!(:object_url).and_return('')
  overview.stub!(:object_title).and_return('Overview')
  overview.stub!(:vetted_id).and_return(Vetted.trusted.id)
  overview.stub!(:video_url).and_return('')
  overview.stub!(:map?).and_return(false)
  overview.stub!(:attributions).and_return([])
  overview.stub!(:description).and_return("<p><em>Cafeteria roenbergensis</em> is a single-celled flagellate from marine environments.  It is D-shaped, and about 5-10 nd has a volume of about 20 µm 3(where 1 µm, a micron, is one-thousandth of a millimeter). It is a eukaryotic organism, with a nucleus, mitochondria and other subcellular compartments. The posterior flagellum attaches the organism to the substrate while it is feeding. If it detaches, the cell will swim around being pulled forward by the beating of the anterior flagellum. When feeding, the action of the anterior flagellum creates a current of water that moves towards the cell. The current carries bacteria, and these are the primary food of the flagellate. The food is ingested below the base of the flagella – this is referred to as the ventral side. The flagella are anchored by ‘rootlets’ ribbons and subcellular ropes. They act as a skeleton and also support the mouth region. Cafeteria roenbergensis was the first species in the genus to be described, and was described only in 1988. It, like many other smaller members of the ocean communities, had largely been overlooked until the 1980s. At that time, it became increasingly evident that bacteria and the organisms that eat them play a very major role in moving food, nutrients and energy in marine ecosystems. As ocean environments are the only environments in which there is a net burial of carbon, a number of major research projects emerged in the1980s to improve our understanding of marine ecosystems typically within the context of global climate change. Cafeteria roenbergensis occurs in all oceans in which they have been looked for, and can grow to very high concentrations (in excess of 10,000 per ml). They are weeds, growing rapidly when food is available and under a reasonably wide range of conditions. It is usually assumed that this species serves as food for larger protozoa or small invertebrate animals, but recent work suggests that the populations are also ‘controlled’ by viruses. Because they are easy to grow, Cafeteria roenbergensis has been subject to a diversity of more detailed studies, such as genomic and ecological studies. From these studies come useful gems such that the mitochondria of all eukaryotes studied, this species have the most functionally compact DNA – with only 3.4% not being used for coding purposes (Hauth et al. 2005).\nThe name Cafeteria reflects the importance of this organism in marine microbial food webs.")
  author = mock_model(Agent)
  author.stub!('ping_host?').and_return(false)
  author.stub!(:full_name).and_return('David J. Patterson')
  author.stub!(:homepage).and_return('')
  author.stub!(:logo_cache_url).and_return(nil)
  overview.stub!(:authors).and_return([author])
  overview.stub!(:sources).and_return([author])
  license = mock_model(License)
  license.stub!(:title).and_return("cc-by 3.0")
  license.stub!(:description).and_return("Some rights reserved")
  license.stub!(:source_url).and_return("http://creativecommons.org/licenses/by/3.0/")
  license.stub!(:version).and_return("0")
  license.stub!(:logo_url).and_return("/images/licenses/cc_by_small.png")
  license.stub!(:small_logo_url).and_return("/images/licenses/cc_by_small.png") # Yes, they are the same.
  overview.stub!(:license).and_return(license)
  return overview
end
  
def mock_videos
  videos = [mock_model(DataObject), mock_model(DataObject)]
  videos[0].stub!(:object_title).and_return('')
  videos[0].stub!(:scientific_name).and_return('')
  videos[0].stub!(:description).and_return("Living cells of <em>Cafeteria roenbergensis</em>")
  videos[0].stub!(:object_cache_url).and_return(2008102401123458)
  videos[0].stub!(:visible_comments).and_return([])
  videos[0].stub!(:video_url).and_return('')
  videos[0].stub!(:authors).and_return([])
  videos[0].stub!(:sources).and_return([])
  videos[0].stub!(:location).and_return('')
  videos[0].stub!(:source_url).and_return('')
  videos[0].stub!(:video_url).and_return('http://content.eol.org/fedora/get/data:280148/LocalVideo.flv')
  videos[0].stub!(:license_text).and_return('Some rights reserved')
  videos[0].stub!(:license_logo).and_return('/images/licenses/cc_by_nc_sa_small.png')
  videos[0].stub!(:license_url).and_return('http://creativecommons.org/licenses/by-nc-sa/3.0/')
  videos[0].stub!(:media_type).and_return('Flash')
  videos[0].stub!(:object_url).and_return('')
  videos[0].stub!(:vetted_id).and_return(Vetted.trusted.id)
  videos[1].stub!(:object_title).and_return('')
  videos[1].stub!(:scientific_name).and_return('')
  videos[1].stub!(:description).and_return('Animation of flagellar beating in <em>Cafeteria roenbergensis</em> (stylized).   Flagella beat with waves of activity passing from base to tip, and this should cause fluids to be pushed away from the body.  In <em>Cafeteria</em>, the flagellar beating draws water towards the body.  This is made possible by two rows of stiff hairs (mastigonemes) that are attached to the active flagellum.  The angle of these changes as the undulation passes such that the tips pull into the water, drawing fluids and suspended particles towards the cell.')
  videos[1].stub!(:object_cache_url).and_return('/fedora/get/data:288573/LocalVideo.flv')
  videos[1].stub!(:video_url).and_return('')
  videos[1].stub!(:authors).and_return([])
  videos[1].stub!(:sources).and_return([])
  videos[1].stub!(:location).and_return('')
  videos[1].stub!(:source_url).and_return('')
  videos[1].stub!(:video_url).and_return('http://content.eol.org/fedora/get/data:280148/LocalVideo.flv')
  videos[1].stub!(:license_text).and_return('Some rights reserved')
  videos[1].stub!(:license_logo).and_return('/images/licenses/cc_by_nc_sa_small.png')
  videos[1].stub!(:license_url).and_return('http://creativecommons.org/licenses/by-nc-sa/3.0/')
  videos[1].stub!(:media_type).and_return('Flash')
  videos[1].stub!(:object_url).and_return('')
  videos[1].stub!(:vetted_id).and_return(Vetted.trusted.id)
  return videos
end

def mock_hierarchy_entry(common_name, sci_name = nil, options = {})
  he = mock_model(HierarchyEntry, options)
  he.stub!(:name).with().and_return(common_name)
  he.stub!(:name).with(:middle, Language.english, :classification).and_return(common_name)
  he.stub!(:name).with('middle', Language.english, :classification).and_return(common_name)
  he.stub!(:name).with(:expert, Language.english, :classification).and_return(sci_name || common_name)
  he.stub!(:valid).and_return(true) unless options.has_key?(:vaid)
  he.stub!(:enable).and_return(true) unless options.has_key?(:enable)
  he.stub!(:taxon_concept_id).and_return(he.id)
  he.stub!(:hierarchy_id).and_return(Hierarchy.default.id)
  he.stub!(:rank_label).and_return('Fake')
  return he
end
