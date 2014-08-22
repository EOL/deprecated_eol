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
  before_save :strip_urls
  after_save :recalculate_statistics

  include EOL::Logos

  # TODO: I don't think it's okay to have hard-coded strings to find an
  # instance in the database that we don't even know is really there.
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
    user && (user_wanting_access.id == user.id || user_wanting_access.is_admin?)
  end

  def unpublished_content?
    resources.any? do |resource|
      resource.latest_harvest_event.nil? ||
        resource.latest_harvest_event.published_at.nil?
    end
  end

  def latest_published_harvest_events
    resources.map(&:latest_published_harvest_event).
      compact.sort_by { |he| he.published_at }.reverse
  end

  def oldest_published_harvest_events
    resources.map(&:oldest_published_harvest_event).
      compact.sort_by { |he| he.published_at }
  end

  def primary_contact
    content_partner_contacts.primary.first ||
      content_partner_contacts.first
  end

  def last_action_date
    dates_to_compare = Set.new([updated_at])
    add_dates(dates_to_compare, resources)
    add_dates(dates_to_compare, content_partner_contacts)
    add_dates(dates_to_compare, content_partner_agreements)
    dates_to_compare.delete(nil).sort.last
  end

  def agreement
    content_partner_agreements.select(&:is_current).sort_by(&:created_at).last
  end

  def name
    display_name.blank? ? full_name : display_name
  end

  def collections
    resources.map(&:collection).compact
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

  def strip_urls
    homepage.strip unless homepage.blank?
  end

  def recalculate_statistics
    EOL::GlobalStatistics.clear(:content_partners)
  end
end
