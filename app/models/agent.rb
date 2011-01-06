# An agent is any person, project or entity that is associated with EOL indexed
# data.  Example of agents include projects, authors, and photographers.
# Any given data object can be associated with multiple agents, each agent
# assigned a differing role based on their association to the associated data object.
#
# Projects that register using the content partner registry will also have a username and a password
# and the ability to log into the content partner system to retrieve reports.  These projects are
# also agents and are associated with any data objects they contribute through the content partner
# registry system.  In order to keep track of their status and movement through the registry, they
# also receive a row in the "content_partner" table, which is linked back to the corresponding agent.
#
# Usernames and passwords are only for agents that register with the content partner
# registry and are distinct from traditional web users (since these logins are for projects instead
# of for individuals.
#
# Agents can also register important individuals associated with the project through AgentContact (q.v.)
class Agent < SpeciesSchemaModel

  belongs_to :agent_status

  has_one :content_partner
  has_one :content_partner_agreement
  has_one :user

  has_many :agent_provided_data_types, :dependent => :destroy
  has_many :agent_data_types, :through => :agent_provided_data_types
  has_many :collections
  has_many :agent_contacts, :dependent => :destroy
  # Because of the tables pluralization these may trip you up sometimes
  has_many :agents_resources, :dependent => :destroy
  has_many :resources, :through => :agents_resources
  has_many :agents_synonyms
  has_many :synonyms, :through => :agents_synonyms
  has_many :google_analytics_partner_summaries
  has_many :google_analytics_partner_taxa


  has_and_belongs_to_many :data_objects

  has_attached_file :logo,
    :path => $LOGO_UPLOAD_DIRECTORY,
    :url => $LOGO_UPLOAD_PATH,
    :default_url => "/images/blank.gif"

  validates_attachment_content_type :logo, 
    :content_type => ['image/pjpeg','image/jpeg','image/png','image/gif', 'image/x-png'],
    :message => "image is not a valid image type", :if => :partner_step?
  validates_attachment_size :logo, :in => 0..0.5.megabyte

  validates_presence_of :project_name
   # Authentication/registration validations
    validates_presence_of     :username
    validates_length_of       :username, :within => 4..16
    validates_uniqueness_of   :username

    with_options :if => :password_required? do |v|
      v.validates_presence_of     :password, :password_confirmation
      v.validates_length_of       :password, :within => 4..16
      v.validates_confirmation_of :password
    end

  # Step validations for content partner registry
  with_options :if => :partner_step do |v|
    v.validates_presence_of :project_description
  end

  # Attributes      
  attr_accessor :partner_step  # true or false indicating if we are on the partner step in the content partner registry so we can do a validation
  attr_accessor :password # virtual password field
  attr_protected :hashed_password, :remember_token, :remember_token_expires_at

  # Callbacks
  before_save :encrypt_password
  before_save :blank_not_null_fields

  # Alias some partner fields so we can use validation helpers
  alias_attribute :project_description, :description

#  validates_uniqueness_of :email   # We will have multiple agents with the same email address, which is actually ok since we don't use it for logins or forgot passwords
  validates_format_of     :email,
       :with => /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i, :message => 'is not a valid e-mail address'

   # Alias some partner fields so we can use validation helpers
  alias_attribute :project_name, :full_name
  alias_attribute :project_abbreviation, :acronym
  alias_attribute :url, :homepage

  # To make users be able to change species pages (add a common name for example)
  # we have create an agent bypassing all the usual safety checks
  def self.create_agent_from_user(thename)
    Agent.with_master do
      agent_id = Agent.connection.insert(
        ActiveRecord::Base.sanitize_sql_array(["INSERT INTO agents (full_name) VALUES (?)", thename]))
      return Agent.find(agent_id)
    end
    return nil
  end

  # Singleton class variable, so we only ever look it up once per thread:  
  def self.iucn
    cached_find(:full_name, 'IUCN', :serialize => true)
  end

  def self.catalogue_of_life
    cached_find(:full_name, 'Catalogue of Life', :serialize => true)
  end

  def self.col
    self.catalogue_of_life
  end

  def self.gbif
    cached_find(:full_name, 'Global Biodiversity Information Facility (GBIF)', :serialize => true)
  end

  def self.ncbi
    cached_find(:full_name, 'National Center for Biotechnology Information', :serialize => true)
  end

  # get the CoL agent for use in classification attribution
  def self.catalogue_of_life_for_attribution
    cached('agents/catalogue_of_life_for_attribution', :serialize => true) do
      col_attr = Agent.catalogue_of_life
      col_attr.full_name = col_attr.display_name = Hierarchy.default.label # To change the name from just "Catalogue of Life"
    end
  end

  def self.boa
    cached_find(:full_name, 'Biology of Aging', :serialize => true)
  end

  def self.from_license(license)
    Agent.new :project_name => license.description,
              :homepage => license.source_url, :logo_url => license.logo_url, :logo_cache_url => 0,
              :logo_file_name => license.logo_url # <-- check for the presence of logo_file name
  end

  def self.just_project_name(location)
    Agent.new :project_name => location
  end

  def self.content_partners_contact_info(month,year)    
    #ac.email
    #'eli@eol.org' email
    SpeciesSchemaModel.connection.select_all("SELECT distinct a.full_name, a.id agent_id, a.username, 
    ac.email
    From agents a
    JOIN content_partners cp                      ON a.id = cp.agent_id
    JOIN google_analytics_partner_summaries gaps  ON cp.agent_id = gaps.agent_id
    JOIN agent_contacts ac                        ON a.id = ac.agent_id
    WHERE gaps.`year` = #{year}
    AND gaps.`month` = #{month} AND ac.email IS NOT NULL ") 
  end

  def self.content_partners_with_published_data
    query = "SELECT distinct a.id, a.full_name 
    FROM agents a
    JOIN agents_resources ar  ON a.id = ar.agent_id
    JOIN harvest_events he    ON ar.resource_id = he.resource_id
    WHERE he.published_at IS NOT NULL
    ORDER BY a.full_name ASC"    
    self.find_by_sql [query]
  end

  def latest_harvest_event
    result = HarvestEvent.find_by_sql("SELECT he.*
    FROM harvest_events he
    JOIN agents_resources ar ON ar.resource_id = he.resource_id
    WHERE ar.agent_id = #{self.id}
    ORDER BY he.id DESC LIMIT 1")
    return nil if result.empty?
    return result[0]
  end

  def self.resources_harvest_events(agent_id,page)
    query = "SELECT ar.resource_id, he.id AS harvest_id, r.title, he.began_at, he.completed_at, he.published_at
    FROM harvest_events he
    JOIN agents_resources ar ON ar.resource_id = he.resource_id
    JOIN resources r ON he.resource_id = r.id
    WHERE ar.agent_id = ?
    ORDER BY ar.resource_id desc, he.id desc"    
    self.paginate_by_sql [query, agent_id], :page => page, :per_page => 30
  end

  def self.published_agent(year, month, page)      
    query="
      SELECT DISTINCT agents.full_name, agents.id
      FROM agents
        JOIN agents_resources ON agents.id = agents_resources.agent_id
        JOIN resources ON agents_resources.resource_id = resources.id
        JOIN harvest_events ON resources.id = harvest_events.resource_id
      WHERE harvest_events.published_at is not null
        AND year(harvest_events.published_at) = ?
        AND month(harvest_events.published_at) = ?
        AND agents.id not in 
          ( SELECT DISTINCT agents.id
            FROM agents
              JOIN agents_resources ON agents.id = agents_resources.agent_id
              JOIN harvest_events ON agents_resources.resource_id = harvest_events.resource_id
            WHERE harvest_events.published_at < '#{year.to_i}-#{sprintf "%02i", month}-01'
              AND harvest_events.published_at IS NOT null
          )
      ORDER BY agents.full_name, harvest_events.id DESC     
    "      
    self.paginate_by_sql [query, year, month], :page => page, :per_page => 50 , :order => 'full_name'    
   end  

  def self.from_source_url(source_url)
    Agent.new :project_name => 'View original data object', :homepage => source_url
  end

  # override the logo_url column in the database to contruct the path on the content server
  def logo_url(size = 'large')
    ContentServer.agent_logo_path(self.attributes['logo_cache_url'], size)
  end

  def self.logo_url_from_cache_url(logo_cache_url, size = 'large')
    ContentServer.agent_logo_path(logo_cache_url, logo_size)
  end

  def node_xml
    xml  = "\t\t<agent>\n";
    xml += "\t\t\t<agentName>#{display_name || full_name}</agentName>\n";
    xml += "\t\t\t<agentHomepage>#{homepage}</agentHomepage>\n";
    xml += "\t\t\t<icon></icon>\n";
    xml += "\t\t\t<smallIcon></smallIcon>\n";
    xml += "\t\t</agent>\n";
    return xml
  end

  ## Helper methods to set columns in associated content partner model by updating attributes of agent
  ##  used in the partner step of the content partner registry where we have one form to update both models
  def project_description
    self.content_partner.project_description unless self.content_partner.nil? 
  end

  def project_description= (description)
    self.content_partner.project_description=description
    self.content_partner.save
  end

  def description_of_data
    self.content_partner.description_of_data unless self.content_partner.nil? 
  end

  def description_of_data= (description_of_data)
    self.content_partner.description_of_data=description_of_data
    self.content_partner.save
  end

  def has_unpublished_content?
    result=false
    self.resources.each do |resource|
      result=(resource.resource_status==ResourceStatus.published)
    end
    return !result
  end

  def notes
    self.content_partner.notes unless self.content_partner.nil? 
  end

  def notes=(notes)
    self.content_partner.notes=notes
    self.content_partner.save
  end

  def admin_notes
    self.content_partner.admin_notes unless self.content_partner.nil? 
  end

  def admin_notes=(admin_notes)
    self.content_partner.admin_notes=admin_notes
    self.content_partner.save
  end

  def primary_contact
    self.agent_contacts.detect {|c| c.agent_contact_role_id == AgentContactRole.primary.id } || self.agent_contacts.first
  end  

  # returns the actual display_name if there is a value in that column, otherwise returns the project name
  def display_name
    if self.attributes['display_name'].nil? || self.attributes['display_name']==''
      return project_name
    else
      return self.attributes['display_name']
    end
  end  

  def shortened_full_name
    return self.full_name.strip[0..50]
  end

  # returns current agreement
  def agreement
    ContentPartnerAgreement.find_by_agent_id_and_is_current(self.id,true)
  end

  def agreement_accepted?
    !self.agreement.nil? && !self.agreement.signed_by.blank? 
  end

  # returns true or false to indicate if current agreement has expired
  def agreement_expired?

    agreement_expired=false

    # see if there is an outdated agreement
    old_agreement=ContentPartnerAgreement.find_by_agent_id_and_is_current(self.id,false)
    if !old_agreement.nil? # if we've got an old agreement, we must have a new one --- check to see if it's been signed, if not - we have an expired agreement
      agreement_expired=true if self.agreement.signed_by.blank?
    end  

    agreement_expired

  end

  # --------------------------------------------------

  # Authenticates a user by their username and unencrypted password.  Returns the user or nil.
  def self.authenticate(username, password)
    a = find_by_username(username)
    a && a.authenticated?(password) && a.agent_status != AgentStatus.inactive ? a : nil
  end

  def authenticated?(password)
    hashed_password == User.hash_password(password)
  end

  def remember_token?
    remember_token_expires_at && Time.now.utc < remember_token_expires_at 
  end

  # These create and unset the fields required for remembering users between browser closes
  def remember_me
    remember_me_for 2.weeks
  end

  def remember_me_for(time)
    remember_me_until time.from_now.utc
  end

  def remember_me_until(time)
    self.remember_token_expires_at = time
    self.remember_token            = User.hash_password("#{email}--#{remember_token_expires_at}")
    self.save(false)
  end

  def forget_me
    self.remember_token_expires_at = nil
    self.remember_token            = nil
    self.save(false)
  end

  def password_required?
    hashed_password.blank? || !password.blank?
  end

  def reset_password!
    pass = random_pronouncable_password
    self.password, self.password_confirmation = pass, pass
    save
    pass
  end  

  def vetted?
    unless self.content_partner.nil? 
      self.content_partner.vetted? 
    else
      false
    end
  end

  def show_on_partner_page?
    unless self.content_partner.nil? 
      self.content_partner.show_on_partner_page? 
    else
      false
    end
  end

  def show_mou_on_partner_page?
    unless self.content_partner.nil? 
      self.content_partner.show_mou_on_partner_page? 
    else
      false
    end
  end

  def show_gallery_on_partner_page?
    unless self.content_partner.nil? 
      self.content_partner.show_gallery_on_partner_page? 
    else
      false
    end
  end

  def show_stats_on_partner_page?
    unless self.content_partner.nil? 
      self.content_partner.show_stats_on_partner_page? 
    else
      false
    end
  end

  def auto_publish?
    unless self.content_partner.nil? 
      self.content_partner.auto_publish? 
    else
      false
    end
  end

  def terms_agreed_to?
    unless self.content_partner.nil?     
      self.content_partner.ipr_accept? && self.content_partner.attribution_accept? && self.content_partner.roles_accept?
    else
      false
    end
  end

  def ready_for_agreement?
    unless self.content_partner.nil?     
      self.agent_contacts.any? && self.content_partner.partner_complete_step? && terms_agreed_to?
    else
      false
    end
  end

  def to_s
    display_name
  end

  alias :ar_to_xml :to_xml
  def to_xml(options = {})
    default_only   = [:id, :acronym, :display_name, :homepage, :username]
    options[:only] = (options[:only] ? options[:only] + default_only : default_only)
    ar_to_xml(options)
  end

  # Find the data_objects "belongs" to an Agent.
  def agents_data
    begin 
      datos = HarvestEvent.find_by_sql(["
          SELECT DISTINCT he.id FROM agents a 
                JOIN agents_resources ar ON (ar.agent_id=a.id)
                JOIN harvest_events he ON (ar.resource_id=he.resource_id) 
                WHERE  (ar.agent_id=? AND he.published_at != '')
                ORDER BY he.id DESC LIMIT 1", self.id])[0].data_objects
    rescue
      datos = ""
    end
    return datos
  end

  # Returns true if the Agent's latest harvest contains this taxon_concept or taxon_concept id (the raw ID is
  # preferred)
  def latest_unpublished_harvest_contains?(taxon_concept_id)
    taxon_concept_id = taxon_concept_id.id if taxon_concept_id.class == TaxonConcept
    resources.each do |resource|
      event = resource.latest_unpublished_harvest_event
      if event # They do HAVE an unpublished event
        tc = TaxonConcept.find_by_sql([%q{
          SELECT tc.id
          FROM taxon_concepts tc
            JOIN hierarchy_entries he ON (tc.id = he.taxon_concept_id)
            JOIN harvest_events_hierarchy_entries hehe ON (he.id = hehe.hierarchy_entry_id)
          WHERE hehe.harvest_event_id = ?
            AND tc.id = ?
        }, event.id, taxon_concept_id])
        return true unless tc.blank?
      end
    end

    # we looked at ALL resources and found none applicable
    return false
  end

  def track_curator_activity(*args)
    user.track_curator_activity(args)
  end

protected

  def encrypt_password
    return if password.blank?
    self.hashed_password = User.hash_password(password)
  end

  def random_pronouncable_password(size = 4)
    v = %w(a e i o u y)
    c = ('a'..'z').to_a - v - ['q'] + %w(qu ch cr fr nd ng nk nt ph pr rd sh sl sp st th tr)
    (1..size).map{[c.rand, v.rand]}.flatten.map{|x| [x,x.upcase].rand}.join('')
  end

  # Set these fields to blank because insistence on having NOT NULL columns on things that aren't populated
  # until certain steps.
  def blank_not_null_fields
    self.homepage       ||= ''
    self[:display_name] ||= ''
    self.full_name      ||= ''
    self[:logo_url]     ||= ''
    self.acronym        ||= ''
    self.homepage = 'http://' + self.homepage if self.homepage != '' && (self.homepage[0..6] != 'http://' && self.homepage[0..7] != 'https://')      
  end

end

