# encoding: utf-8
# EXEMPLAR

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

  def unpublished_content?
    resources.each do |resource|
      # true if resource not yet harvested or latest harvest
      # event not yet published
      return true if resource.latest_harvest_event.nil? ||
        resource.latest_harvest_event.published_at.nil?
    end
    # false if no resources (has no content) or if all resources have
    # latest harvest events and they are published
    false
  end

  def oldest_published_harvest_events
    resources.map(&:oldest_published_harvest_event).
      compact.sort_by { |he| he.published_at }
  end

  def primary_contact
    contact = content_partner_contacts.find do |c|
      c.contact_role_id == ContactRole.primary.id
    end
    contact || content_partner_contacts.first
  end

  # the date of the last action taken
  def last_action
    dates_to_compare = Set.new([updated_at])
    add_dates(dates_to_compare, resources)
    add_dates(dates_to_compare, content_partner_contacts)
    add_dates(dates_to_compare, content_partner_agreements)
    dates_to_compare.delete(nil).sort.last
  end

  def agreement
    current_agreements = content_partner_agreements.
      select { |cpa| cpa.is_current == true }.
        compact.sort_by { |cpa| cpa.created_at }.reverse
    return nil if current_agreements.empty?
    current_agreements[0]
  end

  def name
    return display_name unless display_name.blank?
    full_name
  end

  def collections
    resources.map { |r| r.mapion }.compact
  end

  private

  def add_dates(set, objects)
    return if objects.blank?
    objects.each do |o|
      set << o.updated_at
      set << o.created_at
    end
  end

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
    homepage.strip unless homepage.blank?
  end

  def recalculate_statistics
    EOL::GlobalStatistics.clear("content_partners")
  end
end
