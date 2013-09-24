class Resource < ActiveRecord::Base

  # This class represents some notion of a set of data.  For example, a collection of images of butterflies.

  belongs_to :service_types
  belongs_to :license
  belongs_to :language
  belongs_to :resource_status
  belongs_to :hierarchy
  belongs_to :content_partner
  belongs_to :dwc_hierarchy, :foreign_key => 'dwc_hierarchy_id', :class_name => "Hierarchy"
  belongs_to :collection
  belongs_to :preview_collection, :class_name => Collection.to_s, :foreign_key => :preview_collection_id

  has_many :harvest_events

  has_attached_file :dataset,
    :path => $DATASET_UPLOAD_DIRECTORY,
    :url => $DATASET_URL_PATH

  attr_accessor :latest_published_harvest_event
  attr_protected :latest_published_harvest_event

  before_validation :strip_urls
  before_save :convert_nulls_to_blank # TODO: Make migration to allow null on subject or remove it altogether if its no longer needed

  VALID_RESOURCE_CONTENT_TYPES = ['application/x-gzip', 'application/x-tar', 'text/xml', 'application/vnd.ms-excel',
                                  'application/xml', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
                                  'application/zip']
  validate :validate_dataset_mime_type
  validates_presence_of :title, :license_id
  validates_presence_of :refresh_period_hours, :if => :accesspoint_url_provided?
  validates_presence_of :accesspoint_url, :unless => :dataset_file_provided?
  validates_format_of :accesspoint_url, :allow_blank => true, :allow_nil => true,
                      :with => /(\.xml(\.gz|\.gzip)|\.tgz|\.zip|\.xls|\.xlsx|\.tar\.(gz|gzip))?/
  validates_format_of :dwc_archive_url, :allow_blank => true, :allow_nil => true,
                      :with => /(\.tar\.(gz|gzip)|\.tgz|\.zip)/
  validates_length_of :title, :maximum => 255
  validates_length_of :accesspoint_url, :allow_blank => true, :allow_nil => true, :maximum => 255
  validates_length_of :dwc_archive_url, :allow_blank => true, :allow_nil => true, :maximum => 255
  validates_length_of :description, :allow_blank => true, :allow_nil => true, :maximum => 255
  validates_length_of :rights_holder, :allow_blank => true, :allow_nil => true, :maximum => 255
  validates_length_of :rights_statement, :allow_blank => true, :allow_nil => true, :maximum => 400
  validates_length_of :bibliographic_citation, :allow_blank => true, :allow_nil => true, :maximum => 400
  validates_each :accesspoint_url, :dwc_archive_url do |record, attr, value|
    record.errors.add attr, I18n.t(:inaccessible, :scope => [:activerecord, :errors, :messages, :models]) unless value.blank? || EOLWebService.url_accepted?(value)
  end
  validate :url_or_dataset_not_both

  # TODO: This assumes one to one relationship between user and content partner and will need to be modified when we move to many to many
  def can_be_created_by?(user)
    content_partner.user_id == user.id || user.is_admin?
  end
  # TODO: This assumes one to one relationship between user and content partner and will need to be modified when we move to many to many
  def can_be_read_by?(user)
    content_partner.user_id == user.id || user.is_admin?
  end
  # TODO: This assumes one to one relationship between user and content partner and will need to be modified when we move to many to many
  def can_be_updated_by?(user)
    content_partner.user_id == user.id || user.is_admin?
  end
  # TODO: This assumes one to one relationship between user and content partner and will need to be modified when we move to many to many
  def can_be_deleted_by?(user)
    content_partner.user_id == user.id || user.is_admin?
  end

  def status_can_be_changed_to?(new_status)
    return false if resource_status == new_status
    case new_status
      when ResourceStatus.force_harvest
        !resource_status.blank? &&
        [ResourceStatus.processed, ResourceStatus.processing_failed, ResourceStatus.validated,
         ResourceStatus.validation_failed, ResourceStatus.published].include?(resource_status)
      else
        true
    end
  end

  # trying to change it to memcache got error after reload a page
  def self.iucn
    cached('iucn') do
      Agent.iucn.user.content_partners.first.resources.last
    end
  end

  def self.ligercat
    @@ligercat ||= cached('ligercat') do
      if Agent.boa.user
        Agent.boa.user.content_partners.first.resources.first rescue nil
      else
        content_partner = ContentPartner.boa
        return nil unless content_partner && content_partner.resources && content_partner.resources.first
        content_partner.resources.first rescue nil
      end
    end
  end

  # TODO - generalize this instance-variable reset.
  def reload
    @@ar_instance_vars ||= Resource.new.instance_variables << :mock_proxy # For tests
    (instance_variables - @@ar_instance_vars).each do |ivar|
      remove_instance_variable(ivar)
    end
    super
  end

  def status_label
    (resource_status.nil?) ?  I18n.t(:content_partner_resource_resource_status_new) : resource_status.label
  end

  def oldest_published_harvest_event
    return @oldest_published_harvest if defined? @oldest_published_harvest
    HarvestEvent
    cache_key = "oldest_published_harvest_event_for_resource_#{id}"
    @oldest_published_harvest = Rails.cache.read(Resource.cached_name_for(cache_key))
    # not using fetch as only want to set expiry when there is no harvest event
    if @oldest_published_harvest.nil? #cache miss
      @oldest_published_harvest = HarvestEvent.find(:first,
        :conditions => ["published_at IS NOT NULL AND completed_at IS NOT NULL AND resource_id = ?", id],
        :limit => 1, :order => 'published_at')
      if @oldest_published_harvest.nil?
        # resource not yet published store 0 in cache with expiry so we don't try to find it again for a while
        Rails.cache.write(Resource.cached_name_for(cache_key), 0, :expires_in => 6.hours)
      else
        Rails.cache.write(Resource.cached_name_for(cache_key), @oldest_published_harvest)
      end
    elsif @oldest_published_harvest == 0 # cache hit, resource not yet published so set harvest event to nil
      @oldest_published_harvest = nil
    end
    @oldest_published_harvest
  end

  def latest_published_harvest_event
    return @latest_published_harvest if defined? @latest_published_harvest
    HarvestEvent
    cache_key = "latest_published_harvest_event_for_resource_#{id}"
    @latest_published_harvest = Rails.cache.fetch(Resource.cached_name_for(cache_key), :expires_in => 6.hours) do
      # Uses 0 instead of nil when setting for cache because cache treats nil as a miss
      HarvestEvent.where(["published_at IS NOT NULL AND completed_at IS NOT NULL AND resource_id = ?", id]). \
        order('published_at desc').first || 0
    end
    @latest_published_harvest = nil if @latest_published_harvest == 0 # return nil or HarvestEvent, i.e. not the 0 cache hit
    @latest_published_harvest
  end

  def latest_harvest_event
    return @latest_harvest if defined? @latest_harvest
    HarvestEvent
    cache_key = "latest_harvest_event_for_resource_#{self.id}"
    @latest_harvest = Rails.cache.fetch(Resource.cached_name_for(cache_key), :expires_in => 6.hours) do
      # Use 0 instead of nil when setting for cache because cache treats nil as a miss
      HarvestEvent.where(resource_id: id).last || 0
    end
    @latest_harvest = nil if @latest_harvest == 0 # return nil or HarvestEvent, i.e. not the 0 cache hit
    @latest_harvest
  end

  def upload_resource_to_content_master!(port = nil)
    if self.accesspoint_url.blank?
      self.resource_status = ResourceStatus.uploaded
      ip_with_port = $IP_ADDRESS_OF_SERVER.dup
      ip_with_port += ":" + port if port && !ip_with_port.match(/:[0-9]+$/)
      file_url = "http://" + ip_with_port + $DATASET_UPLOAD_PATH + id.to_s + "."+ dataset_file_name.split(".")[-1]
    else
      file_url = accesspoint_url
    end
    status, response_message = ContentServer.upload_resource(file_url, self.id)
    if status == ResourceStatus.validated
      self.notes = response_message  # reset the notes which may contain previous validation failures
      self.resource_status = ResourceStatus.validated
    else
      if response_message
        self.notes = response_message
        self.resource_status = ResourceStatus.validation_failed
      else
        self.notes = nil  # reset the notes which may contain previous validation failures
        self.resource_status = ResourceStatus.upload_failed
      end
    end
    self.save!
    return self.resource_status
  end

  def from_DiscoverLife?
    return true if self.content_partner.full_name == "Discover Life"
    false
  end

private

  def url_or_dataset_not_both
    if dataset_file_provided? && accesspoint_url_provided?
      errors[:base] << I18n.t('content_partner_resource_url_or_dataset_not_both_error')
    end
  end
  
  def validate_dataset_mime_type
    return true if dataset.blank? || dataset.original_filename.blank?
    require 'mime/types'
    mime_types = MIME::Types.type_for(dataset.original_filename)
    if first_type = mime_types.first
      return true if VALID_RESOURCE_CONTENT_TYPES.include? first_type.to_s
    end
    errors[:base] << I18n.t('activerecord.errors.models.resource.attributes.dataset.wrong_type')
  end
  
  def accesspoint_url_provided?
    !accesspoint_url.blank?
  end

  # checks to see a new file has been attached or we already have a dataset file.
  def dataset_file_provided?
    dataset? || !dataset_file_name.blank?
  end

  def strip_urls
    accesspoint_url.strip! if accesspoint_url
    dwc_archive_url.strip! if dwc_archive_url
  end

  def convert_nulls_to_blank
    self.subject = '' if self.subject.nil?
  end
end

