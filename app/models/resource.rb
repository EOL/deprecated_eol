# A Resource is a dataset or compilation of media provided by a partner, harvested by EOL into data_objects and data_point_uris.
# For example, a collection of images of butterflies.
#
# NOTES:
#
# The following fields store DEFAULT values for items IN the resource:
#     license_id
#     rights_holder
#     rights_statement
# However, the resource ITSELF can be copyrightable in some jurisdictions, so the following apply to the resource as a whole:
#     dataset_license_id
#     dataset_rights_holder
#     dataset_rights_statement
#
# accesspoint_url is THEIR hosted copy of the harvested resource.
# dataset_source_url is the source of the data. ...Say... a paper.
# dataset_hosted_url is OUR hosted copy of the resource.
# dwc_archive_url is specific to LifeDesks, which refused to add taxonomy to their resource files
class Resource < ActiveRecord::Base

  belongs_to :service_types
  belongs_to :license
  belongs_to :dataset_license, class_name: 'License'
  belongs_to :language
  belongs_to :resource_status
  belongs_to :hierarchy
  belongs_to :content_partner
  belongs_to :dwc_hierarchy, class_name: 'Hierarchy'
  belongs_to :collection
  belongs_to :preview_collection, class_name: 'Collection'

  has_many :harvest_events

  scope :by_priority, -> { order(:position) }
  scope :force_harvest,
    -> { where(resource_status_id: ResourceStatus.force_harvest.id) }
  scope :unharvested, -> { where("harvested_at IS NULL") }
  # This is, of course, ridiculous. But it's what is used in PHP, sooo...
  scope :ready, -> do
    where(
      "resource_status_id = #{ResourceStatus.force_harvest.id} OR "\
      "("\
        "harvested_at IS NULL AND ("\
          "resource_status_id = #{ResourceStatus.validated.id} OR "\
          "resource_status_id = #{ResourceStatus.validation_failed.id} OR "\
          "resource_status_id = #{ResourceStatus.processing_failed.id}"\
        ") "\
      ") OR ( "\
        "refresh_period_hours != 0 AND "\
        "DATE_ADD(harvested_at, "\
          "INTERVAL(refresh_period_hours) HOUR) <= NOW() AND "\
        "resource_status_id IN ("\
          "#{ResourceStatus.upload_failed.id}, "\
          "#{ResourceStatus.validated.id}, "\
          "#{ResourceStatus.validation_failed.id}, "\
          "#{ResourceStatus.processed.id}, "\
          "#{ResourceStatus.processing_failed.id}, "\
          "#{ResourceStatus.published.id}"\
        ")"\
      ")"
    )
  end

  # The order of the list affects the order of harvesting:
  acts_as_list

  has_attached_file :dataset,
    path: $DATASET_UPLOAD_DIRECTORY,
    url: $DATASET_URL_PATH

  attr_accessor :latest_published_harvest_event
  attr_protected :latest_published_harvest_event

  before_destroy :destroy_everything
  before_validation :strip_urls
  before_save :convert_nulls_to_blank # TODO: Make migration to allow null on subject or remove it altogether if its no longer needed

  VALID_RESOURCE_CONTENT_TYPES = ['application/x-gzip', 'application/x-tar', 'text/xml', 'application/vnd.ms-excel',
                                  'application/xml', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
                                  'application/zip']
  validates_attachment_content_type :dataset, content_type: VALID_RESOURCE_CONTENT_TYPES, if: :validate_dataset_mime_type?
  validates_presence_of :title, :license_id
  validates_presence_of :refresh_period_hours, if: :accesspoint_url_provided?
  validates_presence_of :accesspoint_url, unless: :dataset_file_provided?
  validates_format_of :accesspoint_url, allow_blank: true, allow_nil: true,
                      with: /(\.xml(\.gz|\.gzip)|\.tgz|\.zip|\.xls|\.xlsx|\.tar\.(gz|gzip))?/
  validates_format_of :dwc_archive_url, allow_blank: true, allow_nil: true,
                      with: /(\.tar\.(gz|gzip)|\.tgz|\.zip)/
  validates_length_of :title, maximum: 255
  validates_length_of :accesspoint_url, allow_blank: true, allow_nil: true, maximum: 255
  validates_length_of :dwc_archive_url, allow_blank: true, allow_nil: true, maximum: 255
  validates_length_of :description, allow_blank: true, allow_nil: true, maximum: 255
  validates_length_of :rights_holder, allow_blank: true, allow_nil: true, maximum: 255
  validates_length_of :rights_statement, allow_blank: true, allow_nil: true, maximum: 400
  validates_length_of :bibliographic_citation, allow_blank: true, allow_nil: true, maximum: 400
  validates_each :accesspoint_url, :dwc_archive_url do |record, attr, value|
    record.errors.add attr, I18n.t(:inaccessible, scope: [:activerecord, :errors, :messages, :models]) unless value.blank? || EOLWebService.url_accepted?(value)
  end
  validate :url_or_dataset_not_both

  def self.next
    ready.by_priority.first
  end

  # TODO: This assumes one to one relationship between user and content partner and will need to be modified when we move to many to many
  def can_be_created_by?(user)
    content_partner.user_id == user.id || user.is_admin?
  end
  # TODO: This assumes one to one relationship between user and content partner and will need to be modified when we move to many to many
  def can_be_read_by?(user)
    true # NOTE - this was changed on 2013-10-18 in order to allow users to see resource pages and get (c) info on them.
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

  def self.iucn_structured_data
    @iucn_structured_data ||= find_by_title("IUCN Structured Data")
  end

  # trying to change it to memcache got error after reload a page
  def self.iucn
    cached('iucn') do
      Agent.iucn.user.content_partners.first.resources.last
    end
  end

  def self.ligercat
    @@ligercat ||= cached('ligercat') do
      Agent.boa.user.content_partners.first.resources.first rescue nil
    end
  end

  def self.add_to_data(rows)
    rows.each{ |r| r[:resource_id] = r[:graph].to_s.split("/").last }
    resources = where(["id in (?)", rows.collect{ |r| r[:resource_id ] }.uniq ])
    preload_associations(resources, [ :content_partner ])
    rows.each do |row|
      row[:resource] = resources.detect{ |r| r.id == row[:resource_id].to_i }
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

  def self.load_for_title_only(find_this)
    Resource.find(find_this)
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
        conditions: ["published_at IS NOT NULL AND completed_at IS NOT NULL AND resource_id = ?", id],
        limit: 1, order: 'published_at')
      if @oldest_published_harvest.nil?
        # resource not yet published store 0 in cache with expiry so we don't try to find it again for a while
        Rails.cache.write(Resource.cached_name_for(cache_key), 0, expires_in: 6.hours)
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
    @latest_published_harvest = Rails.cache.fetch(Resource.cached_name_for(cache_key), expires_in: 6.hours) do
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
    @latest_harvest = Rails.cache.fetch(Resource.cached_name_for(cache_key), expires_in: 6.hours) do
      # Use 0 instead of nil when setting for cache because cache treats nil as a miss
      HarvestEvent.where(resource_id: id).last || 0
    end
    @latest_harvest = nil if @latest_harvest == 0 # return nil or HarvestEvent, i.e. not the 0 cache hit
    @latest_harvest
  end

  def upload_resource_to_content_master!(port = nil)
    if self.accesspoint_url.blank?
      self.resource_status = ResourceStatus.uploaded
      ip_with_port = EOL::Server.ip_address.dup
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

  def destroy_everything
    Rails.logger.error("** Destroying Resource #{id}")
    harvest_events.each(&:destroy_everything)
    begin
      HarvestEvent.delete_all(["resource_id = ?", id])
      # delete all records from resource contributions related to this record
      ResourceContribution.delete_all(["resource_id = ?", self.id])
      delete_resource_contributions_file
    rescue ActiveRecord::StatementInvalid => e
      # This is not *fatal*, it's just unfortunate. Probably because we're
      # harvesting, but waiting for harvests to finish is not possible.
      Rails.logger.error("** Unable to delete from HarvestEvents where "\
        "resource_id = #{id} (#{e.message})")
    end
    Rails.logger.error("** Destroyed Resource #{id}")
  end

  def has_harvest_events?
    harvest_events.blank? ? false : true
  end

  def save_resource_contributions
    resource_contributions = ResourceContribution.where("resource_id = ? ", self.id)
    resource_contributions_json = []
    resource_contributions.each do |resource_contribution|
      taxon_concept_id = resource_contribution.taxon_concept_id
      type = resource_contribution.object_type
      url = type == "data_object" ? "#{Rails.configuration.site_domain}/data_objects/#{resource_contribution.data_object_id}": "#{Rails.configuration.site_domain}/pages/#{resource_contribution.taxon_concept_id}/data#data_point_uri_#{resource_contribution.data_point_uri_id}"
      resource_contribution_json = {
         type: type,
         url: url,
         identifier: resource_contribution.identifier,
         source: resource_contribution.source,
         page: taxon_concept_id
      }
      data_object_type_id = resource_contribution.data_object_type
      if data_object_type_id
        resource_contribution_json[:data_object_type] = DataType.find(data_object_type_id).label
      end
      predicate = resource_contribution.predicate
      if predicate
        resource_contribution_json[:predicate] = predicate
      end
      resource_contributions_json << resource_contribution_json
    end

    resource_info_with_contributions = { id: self.id,
                                         url: "#{Rails.configuration.site_domain}/content_partners/#{self.content_partner_id}/resources/#{self.id}",
                                         title: self.title,
                                         contributions: resource_contributions_json }
    File.open("#{$RESOURCE_CONTRIBUTIONS_DIR}/resource_contributions_#{self.id}.json","w") do |f|
      f.write(JSON.pretty_generate(resource_info_with_contributions))
    end
  end

  def delete_resource_contributions_file
    File.delete("#{$RESOURCE_CONTRIBUTIONS_DIR}/resource_contributions_#{self.id}.json") if File.file?("#{$RESOURCE_CONTRIBUTIONS_DIR}/resource_contributions_#{self.id}.json")
  end

  def self.is_paused?
    Resource.first.pause
  end

private

  def url_or_dataset_not_both
    if dataset_file_provided? && accesspoint_url_provided?
      errors[:base] << I18n.t('content_partner_resource_url_or_dataset_not_both_error')
    end
  end

  def validate_dataset_mime_type?
    ! dataset.blank? && ! dataset.original_filename.blank?
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
