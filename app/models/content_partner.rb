class ContentPartner < SpeciesSchemaModel

  belongs_to :user
  belongs_to :content_partner_status

  has_many :resources, :dependent => :destroy
  has_many :content_partner_contacts, :dependent => :destroy
  # FIXME: http://jira.eol.org/browse/WEB-2995 has_many :google_analytics_partner_summaries is not
  # currently true and does not work it is associated through user but should probably be linked directly
  # to content partner instead (possibly true for partner taxa association too?)
  # has_many :google_analytics_partner_summaries
  has_many :google_analytics_partner_taxa
  has_many :content_partner_agreements

  before_validation_on_create :set_default_content_partner_status

  validates_presence_of :full_name
  validates_presence_of :description
  validates_presence_of :content_partner_status
  validates_presence_of :user
  validates_length_of :display_name, :maximum => 255, :allow_nil => true, :if => Proc.new {|s| s.class.column_names.include?('display_name') }
  validates_length_of :acronym, :maximum => 20, :allow_nil => true, :if => Proc.new {|s| s.class.column_names.include?('acronym') }
  validates_length_of :homepage, :maximum => 255, :allow_nil => true, :if => Proc.new {|s| s.class.column_names.include?('homepage') }

  # Alias some partner fields so we can use validation helpers
  alias_attribute :project_description, :description

  before_save :blank_not_null_fields
  before_save :strip_urls

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


  def can_be_read_by?(user_wanting_access)
    public || (user_wanting_access.id == user_id || user_wanting_access.is_admin?)
  end
  def can_be_updated_by?(user_wanting_access)
    user_wanting_access.id == user_id || user_wanting_access.is_admin?
  end
  def can_be_created_by?(user_wanting_access)
    # NOTE: association with user object must exist for permissions to be checked as user can only have one content partner at the moment
    user && user.content_partner.nil? && (user_wanting_access.id == user.id || user_wanting_access.is_admin?)
  end

#  TODO: change latests published harvest event to eager load or make it work without eager loading
#  def concepts_for_gallery(page, per_page)
#    page = page - 1
#
#    return nil if resources.nil?
#    harvest_event_ids = resources.collect{|r| r.latest_published_harvest_event.id || nil }
#    return nil if harvest_event_ids.empty?
#
#    all_hierarchy_entry_ids = connection.select_values(%Q{
#        SELECT hierarchy_entry_id
#        FROM harvest_events_hierarchy_entries hehe
#        WHERE hehe.harvest_event_id IN (#{harvest_event_ids.join(',')})}).uniq.reverse
#    total_taxa_count = all_hierarchy_entry_ids.length
#
#    start_index = page*per_page
#    end_index = start_index + per_page
#    sorted_hierarchy_entries = connection.execute("
#        SELECT he.id hierarchy_entry_id, he.source_url, n.string scientific_name
#        FROM hierarchy_entries he
#        JOIN names n on (he.name_id=n.id)
#        WHERE he.id IN (#{all_hierarchy_entry_ids[start_index...end_index].join(',')})").all_hashes
#
#    start_index = page * per_page
#    end_index = start_index + per_page
#
#    all_concepts = []
#    for i in 0...total_taxa_count
#      all_concepts[i] = {}
#      if i >= start_index && i < end_index
#
#        entry = sorted_hierarchy_entries[i-start_index]
#        name_and_image = connection.execute("SELECT he.taxon_concept_id, n.string, do.object_cache_url
#          FROM hierarchy_entries he
#          JOIN names n ON (he.name_id=n.id)
#          LEFT JOIN (
#            top_images ti
#            JOIN data_objects do ON (ti.data_object_id=do.id AND ti.view_order=1)
#          ) ON (he.id=ti.hierarchy_entry_id)
#          WHERE he.id=#{entry['hierarchy_entry_id']} LIMIT 1").all_hashes
#
#        all_concepts[i]['id'] = name_and_image[0]['taxon_concept_id']
#        all_concepts[i]['name_string'] = entry['scientific_name']
#        all_concepts[i]['partner_source_url'] = entry['source_url']
#        if name_and_image[0] && !name_and_image[0]['object_cache_url'].nil?
#          all_concepts[i]['image_src'] = DataObject.image_cache_path(name_and_image[0]['object_cache_url'], :medium)
#        else
#          all_concepts[i]['image_src'] = '/images/eol_logo_gray.gif'
#        end
#      end
#    end
#
#    all_concepts
#  end

  # has this partner submitted data_objects which are currently published
  def has_published_resources?
    has_resources = SpeciesSchemaModel.connection.execute(%Q{
        SELECT 1
        FROM resources r
        JOIN harvest_events he ON (r.id = he.resource_id)
        WHERE r.content_partner_id=#{id} AND he.published_at IS NOT NULL LIMIT 1}).all_hashes
    return !has_resources.empty?
  end

#  TODO: change latests published harvest event to eager load or make it work without eager loading
#  def data_objects_curator_activity_log
#    latest_published_harvest_event_ids = []
#    resources.each do |r|
#      if he = r.latest_published_harvest_event
#        latest_published_harvest_event_ids << he.id
#      end
#    end
#    return [] if latest_published_harvest_event_ids.empty?
#
#    objects_history = CuratorActivityLog.find_by_sql(%Q{
#      SELECT ah.*, do.data_type_id, dt.label data_object_type_label, 'data_object' history_type
#      FROM #{DataObjectsHarvestEvent.full_table_name} dohe
#      JOIN #{DataObject.full_table_name} do ON (dohe.data_object_id=do.id)
#      JOIN #{DataType.full_table_name} dt ON (do.data_type_id=dt.id)
#      JOIN #{CuratorActivityLog.full_table_name} ah ON (do.id=ah.object_id)
#      WHERE dohe.harvest_event_id IN (#{latest_published_harvest_event_ids.join(',')})
#      AND ah.changeable_object_type_id=#{ChangeableObjectType.find_by_ch_object_type('data_object').id}
#    }).uniq
#
#    objects_history.sort! do |a,b|
#      b.created_at <=> a.created_at
#    end
#  end

#  TODO: change latests published harvest event to eager load or make it work without eager loading
#  def comments_curator_activity_log
#    latest_published_harvest_event_ids = []
#    resources.each do |r|
#      if he = r.latest_published_harvest_event
#        latest_published_harvest_event_ids << he.id
#      end
#    end
#    return [] if latest_published_harvest_event_ids.empty?
#    comments_history = CuratorActivityLog.find_by_sql(%Q{
#      SELECT ah.*, do.data_type_id, dt.label data_object_type_label, c.body comment_body, 'comment' history_type
#      FROM #{DataObjectsHarvestEvent.full_table_name} dohe
#      JOIN #{DataObject.full_table_name} do ON (dohe.data_object_id=do.id)
#      JOIN #{DataType.full_table_name} dt ON (do.data_type_id=dt.id)
#      JOIN #{Comment.full_table_name} c ON (do.id=c.parent_id)
#      JOIN #{CuratorActivityLog.full_table_name} ah ON (c.id=ah.object_id)
#      WHERE dohe.harvest_event_id IN (#{latest_published_harvest_event_ids.join(',')})
#      AND ah.changeable_object_type_id=#{ChangeableObjectType.find_by_ch_object_type('comment').id}
#      AND c.parent_type = 'DataObject'
#    }).uniq
#    comments_history.sort! do |a,b|
#      b.created_at <=> a.created_at
#    end
#  end

#  TODO: change latests published harvest event to eager load or make it work without eager loading
#  def taxa_comments
#    latest_published_harvest_event_ids = []
#    resources.each do |r|
#      if he = r.latest_published_harvest_event
#        latest_published_harvest_event_ids << he.id
#      end
#    end
#    return [] if latest_published_harvest_event_ids.empty?
#    comments_history = Comment.find_by_sql(%Q{
#      SELECT c.*
#      From #{HarvestEventsHierarchyEntry.full_table_name} hehe
#      Join #{HierarchyEntry.full_table_name} he ON hehe.hierarchy_entry_id = he.id
#      Join #{Comment.full_table_name} c ON he.taxon_concept_id = c.parent_id
#      WHERE hehe.harvest_event_id IN (#{latest_published_harvest_event_ids.join(',')})
#      AND c.parent_type = 'TaxonConcept'
#    }).uniq
#    comments_history.sort! do |a,b|
#      b.created_at <=> a.created_at
#    end
#  end

  def self.with_published_data
    published_partner_ids = connection.select_values("SELECT r.content_partner_id
    FROM resources r
    JOIN harvest_events he ON (r.id = he.resource_id)
    WHERE he.published_at IS NOT NULL")
    ContentPartner.find_all_by_id(published_partner_ids, :order => "full_name")
  end

  def self.boa
    cached_find(:full_name, 'Biology of Aging')
  end

  def all_harvest_events
    all_harvest_events = []
    resources.each do |r|
      if he = r.harvest_events
        all_harvest_events += he
      end
    end
  end

  def latest_published_harvest_events
    resources.collect(&:latest_published_harvest_event).compact.sort_by{|he| he.published_at}.reverse
  end

  def oldest_published_harvest_events
    resources.collect(&:oldest_published_harvest_event).compact.sort_by{|he| he.published_at}
  end

  # Returns true if the Content Partner's latest harvest contains this taxon_concept or taxon_concept id (the raw ID is
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

  # the date of the last action taken
  def last_action
    dates_to_compare = [updated_at]
    # get last updated at from various associations, note updated_at may be nil so we add default || 0 to prevent sort_by exception
    unless resources.blank?
      dates_to_compare << resources.sort_by{ |r| r.updated_at || 0 }[0].updated_at
    end
    unless content_partner_contacts.blank?
      dates_to_compare << content_partner_contacts.sort_by{ |c| c.updated_at || 0 }[0].updated_at
    end
    unless content_partner_agreements.blank?
      dates_to_compare << content_partner_agreements.sort_by{ |a| a.updated_at || 0 }[0].updated_at
    end
    dates_to_compare.compact!
    return dates_to_compare.sort[0] if dates_to_compare
  end

  def agreement
    current_agreements = content_partner_agreements.select{ |cpa| cpa.is_current == true }.compact.sort_by{|cpa| cpa.created_at}.reverse
    return nil if current_agreements.empty?
    current_agreements[0]
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

  def self.resources_harvest_events(content_partner_id, page)
    query = "SELECT r.id resource_id, he.id AS harvest_id, r.title, he.began_at, he.completed_at, he.published_at
    FROM content_partners cp
    JOIN resources r ON cp.id = r.content_partner_id
    JOIN harvest_events he ON he.resource_id = r.id
    WHERE cp.id = #{content_partner_id}
    ORDER BY r.id desc, he.id desc"
    self.paginate_by_sql [query, content_partner_id], :page => page, :per_page => 30
  end

private
  def set_default_content_partner_status
    self.content_partner_status = ContentPartnerStatus.active if self.content_partner_status.blank?
  end

  # Set these fields to blank because insistence on having NOT NULL columns on things that aren't populated
  # until certain steps.
  def blank_not_null_fields
    self.notes ||= ""
    self.description_of_data ||= ""
    self.description ||=""
  end

  def strip_urls
    self.homepage.strip unless self.homepage.blank?
  end

end
