# encoding: utf-8

# EXEMPLAR: Read more about exemplars at RAILS_ROOT/doc/STYLE_GUIDE.md
# ContentPartner model describes EOL content partners
class ContentPartner < ActiveRecord::Base
  belongs_to :user
  belongs_to :content_partner_status

  has_many :resources, dependent: :destroy
  has_many :content_partner_contacts, dependent: :destroy
  has_many :google_analytics_partner_taxa
  has_many :content_partner_agreements

  alias_attribute :project_description, :description

  validates_presence_of :full_name
  validates_presence_of :description
  validates_presence_of :user
  validates_length_of :display_name, maximum: 255, allow_nil: true
  validates_length_of :acronym, maximum: 20, allow_nil: true
  validates_length_of :homepage, maximum: 255, allow_nil: true

  before_save :default_content_partner_status
  before_save :blank_not_null_fields
  before_save :strip_urls
  after_save :recalculate_statistics

  include EOL::Logos

  def self.boa
    cached_find(:full_name, "Biology of Aging")
  end

  @wikipedia = nil

  def self.wikipedia
    @wikipedia ||= cached_find(:full_name, "Wikipedia")
  end

  def can_be_read_by?(user_wanting_access)
    is_public || (user_wanting_access.id == user_id ||
               user_wanting_access.is_admin?)
  end

  def can_be_updated_by?(user_wanting_access)
    user_wanting_access.id == user_id || user_wanting_access.is_admin?
  end

  def can_be_created_by?(user_wanting_access)
    # NOTE: association with user object must exist for permissions to be
    # checked as user can only have one content partner at the moment
    user && (user_wanting_access.id == user.id || user_wanting_access.is_admin?)
  end

  def has_unpublished_content?
    self.resources.each do |resource|
      # true if resource not yet harvested or latest harvest
      # event not yet published
      return true if resource.latest_harvest_event.nil? ||
        resource.latest_harvest_event.published_at.nil?
    end
    # false if no resources (has no content) or if all resources have
    # latest harvest events and they are published
    return false
  end

  def self.resources_harvest_events(content_partner_id, page)
    query = "
      SELECT r.id resource_id, he.id
          AS harvest_id, r.title, he.began_at, he.completed_at, he.published_at
      FROM content_partners cp
      JOIN resources r ON cp.id = r.content_partner_id
      JOIN harvest_events he ON he.resource_id = r.id
      WHERE cp.id = #{content_partner_id}
      ORDER BY r.id desc, he.id desc
    "
    self.paginate_by_sql [query, content_partner_id], page: page, per_page: 30
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
    resources.collect(&:latest_published_harvest_event).
      compact.sort_by{|he| he.published_at}.reverse
  end

  def oldest_published_harvest_events
    resources.collect(&:oldest_published_harvest_event).
      compact.sort_by{|he| he.published_at}
  end

  def primary_contact
    self.content_partner_contacts.detect {|c| c.contact_role_id ==
      ContactRole.primary.id } || self.content_partner_contacts.first
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
    current_agreements = content_partner_agreements.
      select { |cpa| cpa.is_current == true }.
        compact.sort_by{ |cpa| cpa.created_at}.reverse
    return nil if current_agreements.empty?
    current_agreements[0]
  end

  def name
    return display_name unless display_name.blank?
    full_name
  end

  def collections
    resources.map { |r| r.collection }.compact
  end

  private

  def default_content_partner_status
    self.content_partner_status ||= ContentPartnerStatus.active
  end

  # Set these fields to blank because insistence on having NOT NULL
  # columns on things that aren't populated until certain steps.
  def blank_not_null_fields
    self.notes ||= ""
    self.description_of_data ||= ""
    self.description ||= ""
  end

  def strip_urls
    self.homepage.strip unless self.homepage.blank?
  end

  def recalculate_statistics
    EOL::GlobalStatistics.clear("content_partners")
  end
end
