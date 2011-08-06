# This is a special kind of Agent (the relationship is mandatory; q.v.).  A ContentPartner is akin to a User, in that
# they can log in (see ContentPartnerController).  Of course, content partners are those people or organizations who
# add data to our database.
class ContentPartner < SpeciesSchemaModel

  belongs_to :user
  belongs_to :content_partner_status

  has_many :resources
  has_many :content_partner_contacts, :dependent => :destroy
  has_many :google_analytics_partner_summaries
  has_many :google_analytics_partner_taxa
  has_many :content_partner_agreements

  validates_presence_of :full_name
  validates_presence_of :description
  validates_length_of :display_name, :maximum => 255, :allow_nil => true
  validates_length_of :acronym, :maximum => 20, :allow_nil => true
  validates_length_of :homepage, :maximum => 255, :allow_nil => true

  #STEPS = [:partner, :contacts, :licensing, :attribution, :roles, :transfer_overview, :transfer_upload, :specialist_overview, :specialist_formatting]

  # Alias some partner fields so we can use validation helpers
  alias_attribute :project_description, :description

  #validate :validate_atleast_one_contact, :if => :contacts_step?
  # REMOVE VALIDATION FOR THESE STEPS TO ALLOW PEOPLE TO 'UNACCEPT', Peter Mangiafico, Sep 12, 2008
  #validate :validate_ipr_acceptance, :if => :licensing_step?
  #validate :validate_attribution_acceptance, :if => :attribution_step?
  #validate :validate_roles_acceptance, :if => :roles_step?

  # Callbacks
  before_save :blank_not_null_fields

  # TODO: remove the :if condition after migrations are run in production
  has_attached_file :logo,
    :path => $LOGO_UPLOAD_DIRECTORY,
    :url => $LOGO_UPLOAD_PATH,
    :default_url => "/images/blank.gif",
    :if => self.column_names.include?('logo_file_name')

  validates_attachment_content_type :logo,
    :content_type => ['image/pjpeg','image/jpeg','image/png','image/gif', 'image/x-png'],
    :if => self.column_names.include?('logo_file_name')
  validates_attachment_size :logo, :in => 0..$LOGO_UPLOAD_MAX_SIZE,
    :if => self.column_names.include?('logo_file_name')

  # TODO: This assumes one to one relationship between user and content partner and will need to be modified when we go to many to many
  def can_be_updated_by?(user)
    user.id == user_id || user.is_admin?
  end

  def concepts_for_gallery(page, per_page)
    page = page - 1

    return nil if resources.nil?
    harvest_event_ids = resources.collect{|r| r.latest_published_harvest_event.id || nil }
    return nil if harvest_event_ids.empty?

    all_hierarchy_entry_ids = connection.select_values(%Q{
        SELECT hierarchy_entry_id
        FROM harvest_events_hierarchy_entries hehe
        WHERE hehe.harvest_event_id IN (#{harvest_event_ids.join(',')})}).uniq.reverse
    total_taxa_count = all_hierarchy_entry_ids.length

    start_index = page*per_page
    end_index = start_index + per_page
    sorted_hierarchy_entries = connection.execute("
        SELECT he.id hierarchy_entry_id, he.source_url, n.string scientific_name
        FROM hierarchy_entries he
        JOIN names n on (he.name_id=n.id)
        WHERE he.id IN (#{all_hierarchy_entry_ids[start_index...end_index].join(',')})").all_hashes

    start_index = page * per_page
    end_index = start_index + per_page

    all_concepts = []
    for i in 0...total_taxa_count
      all_concepts[i] = {}
      if i >= start_index && i < end_index

        entry = sorted_hierarchy_entries[i-start_index]
        name_and_image = connection.execute("SELECT he.taxon_concept_id, n.string, do.object_cache_url
          FROM hierarchy_entries he
          JOIN names n ON (he.name_id=n.id)
          LEFT JOIN (
            top_images ti
            JOIN data_objects do ON (ti.data_object_id=do.id AND ti.view_order=1)
          ) ON (he.id=ti.hierarchy_entry_id)
          WHERE he.id=#{entry['hierarchy_entry_id']} LIMIT 1").all_hashes

        all_concepts[i]['id'] = name_and_image[0]['taxon_concept_id']
        all_concepts[i]['name_string'] = entry['scientific_name']
        all_concepts[i]['partner_source_url'] = entry['source_url']
        if name_and_image[0] && !name_and_image[0]['object_cache_url'].nil?
          all_concepts[i]['image_src'] = DataObject.image_cache_path(name_and_image[0]['object_cache_url'], :medium)
        else
          all_concepts[i]['image_src'] = '/images/eol_logo_gray.gif'
        end
      end
    end

    all_concepts
  end

  # has this partner submitted data_objects which are currently published
  def has_published_resources?
    has_resources = SpeciesSchemaModel.connection.execute(%Q{
        SELECT 1
        FROM resources r
        JOIN harvest_events he ON (r.id = he.resource_id)
        WHERE r.content_partner_id=#{id} AND he.published_at IS NOT NULL LIMIT 1}).all_hashes
    return !has_resources.empty?
  end

  def data_objects_curator_activity_log
    latest_published_harvest_event_ids = []
    resources.each do |r|
      if he = r.latest_published_harvest_event
        latest_published_harvest_event_ids << he.id
      end
    end
    return [] if latest_published_harvest_event_ids.empty?

    objects_history = CuratorActivityLog.find_by_sql(%Q{
      SELECT ah.*, do.data_type_id, dt.label data_object_type_label, 'data_object' history_type
      FROM #{DataObjectsHarvestEvent.full_table_name} dohe
      JOIN #{DataObject.full_table_name} do ON (dohe.data_object_id=do.id)
      JOIN #{DataType.full_table_name} dt ON (do.data_type_id=dt.id)
      JOIN #{CuratorActivityLog.full_table_name} ah ON (do.id=ah.object_id)
      WHERE dohe.harvest_event_id IN (#{latest_published_harvest_event_ids.join(',')})
      AND ah.changeable_object_type_id=#{ChangeableObjectType.find_by_ch_object_type('data_object').id}
    }).uniq

    objects_history.sort! do |a,b|
      b.created_at <=> a.created_at
    end
  end

  def comments_curator_activity_log
    latest_published_harvest_event_ids = []
    resources.each do |r|
      if he = r.latest_published_harvest_event
        latest_published_harvest_event_ids << he.id
      end
    end
    return [] if latest_published_harvest_event_ids.empty?
    comments_history = CuratorActivityLog.find_by_sql(%Q{
      SELECT ah.*, do.data_type_id, dt.label data_object_type_label, c.body comment_body, 'comment' history_type
      FROM #{DataObjectsHarvestEvent.full_table_name} dohe
      JOIN #{DataObject.full_table_name} do ON (dohe.data_object_id=do.id)
      JOIN #{DataType.full_table_name} dt ON (do.data_type_id=dt.id)
      JOIN #{Comment.full_table_name} c ON (do.id=c.parent_id)
      JOIN #{CuratorActivityLog.full_table_name} ah ON (c.id=ah.object_id)
      WHERE dohe.harvest_event_id IN (#{latest_published_harvest_event_ids.join(',')})
      AND ah.changeable_object_type_id=#{ChangeableObjectType.find_by_ch_object_type('comment').id}
      AND c.parent_type = 'DataObject'
    }).uniq
    comments_history.sort! do |a,b|
      b.created_at <=> a.created_at
    end
  end

  def taxa_comments
    latest_published_harvest_event_ids = []
    resources.each do |r|
      if he = r.latest_published_harvest_event
        latest_published_harvest_event_ids << he.id
      end
    end
    return [] if latest_published_harvest_event_ids.empty?
    comments_history = Comment.find_by_sql(%Q{
      SELECT c.*
      From #{HarvestEventsHierarchyEntry.full_table_name} hehe
      Join #{HierarchyEntry.full_table_name} he ON hehe.hierarchy_entry_id = he.id
      Join #{Comment.full_table_name} c ON he.taxon_concept_id = c.parent_id
      WHERE hehe.harvest_event_id IN (#{latest_published_harvest_event_ids.join(',')})
      AND c.parent_type = 'TaxonConcept'
    }).uniq
    comments_history.sort! do |a,b|
      b.created_at <=> a.created_at
    end
  end

  def self.with_published_data
    published_partner_ids = connection.select_values("SELECT r.content_partner_id
    FROM resources r
    JOIN harvest_events he ON (r.id = he.resource_id)
    WHERE he.published_at IS NOT NULL")
    ContentPartner.find_all_by_id(published_partner_ids)
  end

  def all_harvest_events
    all_harvest_events = []
    resources.each do |r|
      if he = r.harvest_events
        all_harvest_events += he
      end
    end
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

  def self.partners_published_in_month(year, month)
    start_time = Time.mktime(year, month)
    end_time = Time.mktime(year, month) + 1.month

    previously_published_partner_ids = connection.select_values("SELECT r.content_partner_id
      FROM resources r
      JOIN harvest_events he ON (r.id = he.resource_id)
      WHERE he.published_at < '#{start_time.mysql_timestamp}'")

    published_partner_ids = connection.select_values("SELECT r.content_partner_id
      FROM resources r
      JOIN harvest_events he ON (r.id = he.resource_id)
      WHERE he.published_at BETWEEN '#{start_time.mysql_timestamp}' AND '#{end_time.mysql_timestamp}'")
    ContentPartner.find_all_by_id(published_partner_ids - previously_published_partner_ids)
  end

  def has_unpublished_content?
    result=false
    self.resources.each do |resource|
      result=(resource.resource_status==ResourceStatus.published)
    end
    return !result
  end

  def primary_contact
    self.content_partner_contacts.detect {|c| c.contact_role_id == ContactRole.primary.id } || self.content_partner_contacts.first
  end

  # the date of the last action taken (the last time a contact was updated, or a step was viewed, or a resource was added/edited/published)
  def last_action
    dates_to_compare = [self.partner_seen_step, self.partner_complete_step, self.contacts_seen_step, self.contacts_complete_step,
                        self.licensing_seen_step, self.licensing_complete_step, self.attribution_seen_step, self.attribution_complete_step,
                        self.roles_seen_step, self.roles_complete_step, self.transfer_overview_seen_step, self.transfer_overview_complete_step,
                        self.transfer_upload_seen_step, self.transfer_upload_complete_step]
    resources=self.agent.resources.compact!
    if resources
      dates_to_compare << resources.sort_by{ |m| m.created_at }[0].created_at
    end
    dates_to_compare.compact!
    if dates_to_compare
      dates_to_compare.sort[0]
    else
      nil
    end
  end

  # Store when the user has first 'seen' this step
  def log_seen_step!(step)
    step_method = "#{step}_seen_step"
    if self.respond_to?(step_method)
      self.update_attribute(step_method.to_sym, Time.now.utc)
    end
  end

  # This was in a callback but just caused too many issues.
  def log_completed_step!(step)
    step_method = "#{step}_complete_step"
    if self.respond_to?(step_method)
      self.update_attribute(step_method.to_sym, Time.now.utc)
    end
    if self.ready_for_agreement? && eol_notified_of_acceptance.nil?
       Notifier::deliver_agent_is_ready_for_agreement(self.user, $CONTENT_PARTNER_REGISTRY_EMAIL_ADDRESS)
       self.update_attribute(:eol_notified_of_acceptance, Time.now.utc)
    end
  end

  # Called when contact_step? is true
  def validate_atleast_one_contact
    errors.add_to_base('You must have at least one contact') unless self.content_partner_contacts.any?
  end

  # Called when licensing_step? is true
  def validate_ipr_acceptance
   errors.add_to_base('You must accept the EOL Licensing Policy') unless self.ipr_accept.to_i == 1
  end

  # Called when attribution_step? is true
  def validate_attribution_acceptance
    errors.add_to_base('You must accept the EOL Attribution Guidelines') unless self.attribution_accept.to_i == 1
  end

  # Called when roles_step? is true
  def validate_roles_acceptance
    errors.add_to_base('You must accept the EOL Roles Guidelines') unless self.roles_accept.to_i == 1
  end

  def roles_accept?
    EOLConvert.to_boolean(roles_accept)
  end

  def ipr_accept?
    EOLConvert.to_boolean(ipr_accept)
  end

  def attribution_accept?
    EOLConvert.to_boolean(attribution_accept)
  end

  def transfer_schema_accept?
    EOLConvert.to_boolean(transfer_schema_accept)
  end

  def terms_agreed_to?
    ipr_accept? && attribution_accept? && roles_accept?
  end

  def ready_for_agreement?
    content_partner_contacts.any? && partner_complete_step? && terms_agreed_to?
  end

  def agreement
    current_agreements = content_partner_agreements.select{ |cpa| cpa.is_current == true }
    return nil if current_agreements.empty?
    current_agreements[0]
  end

  def previous_agreement
    previous_agreements = content_partner_agreements.select{ |cpa| cpa.is_current == false }
    return nil if previous_agreements.empty?
    previous_agreements[0]
  end

  # returns true or false to indicate if current agreement has expired
  def agreement_expired?
    # if we've got an old agreement, we must have a new one --- check to see if it's been signed, if not - we have an expired agreement
    if previous_agreement
      return true if agreement && agreement.signed_by.blank?
    end
    false
  end

  def agreement_accepted?
    agreement && !agreement.signed_by.blank?
  end

  # vet or unvet entire content partner (0 = unknown, 1 = vet)
  def set_vetted_status(vetted)
    set_to_state = EOLConvert.to_boolean(vetted) ? Vetted.trusted.id : Vetted.unknown.id
    connection.execute("
      UPDATE resources r
      JOIN harvest_events he ON (r.id = he.resource_id)
      JOIN data_objects_harvest_events dohe ON (he.id = dohe.harvest_event_id)
      JOIN data_objects do ON (dohe.data_object_id = do.id)
      SET do.vetted_id = #{set_to_state}
      WHERE r.content_partner_id = #{self.id}
      AND do.curated = 0
      AND do.vetted_id != #{set_to_state}")
    self.vetted = vetted
  end

  # Set these fields to blank because insistence on having NOT NULL columns on things that aren't populated
  # until certain steps.
  def blank_not_null_fields
    self.notes ||= ""
    self.description_of_data ||= ""
    self.description ||=""
  end

  # override the logo_url column in the database to construct the path on the content server
  def logo_url(size = 'large')
    if logo_cache_url.blank?
      return "v2/logos/partner_default.png"
    elsif size.to_s == 'small'
      DataObject.image_cache_path(logo_cache_url, '88_88')
    else
      DataObject.image_cache_path(logo_cache_url, '130_130')
      # ContentServer.logo_path(logo_cache_url, size)
    end
  end

  def name
    return display_name unless display_name.blank?
    full_name
  end
end
