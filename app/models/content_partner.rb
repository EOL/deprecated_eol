class ContentPartner < ActiveRecord::Base

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
    user && user.content_partners.blank? && (user_wanting_access.id == user.id || user_wanting_access.is_admin?)
  end

  # has this partner submitted data_objects which are currently published
  def has_published_resources?
    has_resources = ActiveRecord::Base.connection.execute(%Q{
        SELECT 1
        FROM resources r
        JOIN harvest_events he ON (r.id = he.resource_id)
        WHERE r.content_partner_id=#{id} AND he.published_at IS NOT NULL LIMIT 1}).all_hashes
    return !has_resources.empty?
  end

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

  def self.wikipedia
    cached_find(:full_name, 'Wikipedia')
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
    self.resources.each do |resource|
      # true if resource not yet harvested or latest harvest event not yet published
      return true if resource.latest_harvest_event.nil? || resource.latest_harvest_event.published_at.nil?
    end
    return false # false if no resources (has no content) or if all resources have latest harvest events and they are published
  end

  def primary_contact
    self.content_partner_contacts.detect {|c| c.contact_role_id == ContactRole.primary.id } || self.content_partner_contacts.first
  end

  # the date of the last action taken
  def last_action
    dates_to_compare = [updated_at]
    unless resources.blank?
      dates_to_compare += resources.collect{|r| r.updated_at}
      dates_to_compare += resources.collect{|r| r.created_at}
    end
    unless content_partner_contacts.blank?
      dates_to_compare += content_partner_contacts.collect{|c| c.updated_at}
      dates_to_compare += content_partner_contacts.collect{|c| c.created_at}
    end
    unless content_partner_agreements.blank?
      dates_to_compare += content_partner_agreements.collect{|a| a.updated_at}
      dates_to_compare += content_partner_agreements.collect{|a| a.created_at}
    end
    dates_to_compare.compact!
    dates_to_compare.blank? ? nil : dates_to_compare.sort.last
  end

  def agreement
    current_agreements = content_partner_agreements.select{ |cpa| cpa.is_current == true }.compact.sort_by{|cpa| cpa.created_at}.reverse
    return nil if current_agreements.empty?
    current_agreements[0]
  end

  # override the logo_url column in the database to construct the path on the content server
  def logo_url(size = 'large', specified_content_host = nil)
    if logo_cache_url.blank?
      return "v2/logos/partner_default.png"
    elsif size.to_s == 'small'
      DataObject.image_cache_path(logo_cache_url, '88_88', specified_content_host)
    else
      DataObject.image_cache_path(logo_cache_url, '130_130', specified_content_host)
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
