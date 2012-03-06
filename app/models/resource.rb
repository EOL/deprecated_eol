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

  validates_attachment_content_type :dataset,
      :content_type => ['application/x-gzip','application/x-tar','text/xml'],
      :message => I18n.t('activerecord.errors.models.resource.attributes.dataset.wrong_type')

  validates_presence_of :title, :license_id
  validates_presence_of :refresh_period_hours, :if => :accesspoint_url_provided?
  validates_presence_of :accesspoint_url, :unless => :dataset_file_provided?
  validates_format_of :accesspoint_url, :allow_blank => true, :allow_nil => true,
                      :with => /\.xml(\.gz|\.gzip)?/
  validates_format_of :dwc_archive_url, :allow_blank => true, :allow_nil => true,
                      :with => /(\.tar\.(gz|gzip)|.tgz)/
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
        !resource_status.blank? && resource_status != ResourceStatus.being_processed
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
    cached('ligercat') do
      unless Agent.boa.user.blank?
        Agent.boa.user.content_partners.first.resources[0]
      else
        content_partner = ContentPartner.boa
        return nil unless content_partner && content_partner.resources && content_partner.resources.first
        content_partner.resources.first
      end
    end
  end

  def status_label
    (resource_status.nil?) ?  I18n.t(:content_partner_resource_resource_status_new) : resource_status.label
  end

  # TODO: We probably don't need this - and not sure its being used correctly anyway. It's being called
  # by taxa controller accessible_page? method which I don't think is needed anymore, some code clean up
  # probably needed in taxa controller.
  def latest_unpublished_harvest_event
    return @latest_unpublished_harvest if defined? @latest_unpublished_harvest # avoid running query twice if result was nil
    @latest_unpublished_harvest = HarvestEvent.find(:first,
        :conditions => ["published_at IS NULL AND completed_at IS NOT NULL AND resource_id = ?", id],
        :limit => 1, :order => 'completed_at desc')
  end

  def latest_published_harvest_event
    return @latest_published_harvest if defined? @latest_published_harvest # avoid running query twice if result was nil
    @latest_published_harvest = HarvestEvent.find(:first,
       :conditions => ["published_at IS NOT NULL AND completed_at IS NOT NULL AND resource_id = ?", id],
       :limit => 1, :order => 'published_at desc')
  end

  def oldest_published_harvest_event
    return @oldest_published_harvest if defined? @oldest_published_harvest # avoid running query twice if result was nil
    @oldest_published_harvest = HarvestEvent.find(:first,
        :conditions => ["published_at IS NOT NULL AND completed_at IS NOT NULL AND resource_id = ?", id],
        :limit => 1, :order => 'published_at')
  end

  def latest_harvest_event
    return @latest_harvest if defined? @latest_harvest # avoid running query twice if result was nil
    @latest_harvest = HarvestEvent.find(:first, :limit => 1, :order => 'id DESC', :conditions => ["resource_id = ?", id])
  end

#  # vet or unvet entire resource (0 = unknown, 1 = vet)
#  def set_vetted_status(vetted)
#    set_to_state = EOLConvert.to_boolean(vetted) ? Vetted.trusted.id : Vetted.unknown.id
#
#    # update the vetted_id of all data_objects associated with the latest
#    connection.execute("update harvest_events he straight_join data_objects_harvest_events dohe on (he.id=dohe.harvest_event_id) straight_join data_objects do on (dohe.data_object_id=do.id) set do.vetted_id = #{set_to_state} where do.vetted_id = 0 and he.resource_id = #{self.id}")
#
#    if set_to_state == Vetted.trusted.id && !hierarchy.nil?
#      # update the vetted_id of all concepts associated with this resource - only vet them never unvet them
#      connection.execute("UPDATE hierarchy_entries he JOIN taxon_concepts tc ON (he.taxon_concept_id=tc.id) SET tc.vetted_id=#{Vetted.trusted.id} WHERE hierarchy_id=#{hierarchy.id}")
#    end
#
#    self.vetted=vetted
#
#    true
#  end

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
    if status == 'success'
      self.resource_status = response_message
    else
      if response_message
        notes = response_message
        self.resource_status = ResourceStatus.validation_failed
      else
        self.resource_status = ResourceStatus.upload_failed
      end
    end
    self.save!
    return resource_status
  end

  def from_DiscoverLife?
    return true if self.content_partner.full_name == "Discover Life"
    false
  end

private

  def url_or_dataset_not_both
    if dataset_file_provided? && accesspoint_url_provided?
      errors.add_to_base I18n.t('content_partner_resource_url_or_dataset_not_both_error')
    end
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

