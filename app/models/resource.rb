class Resource < SpeciesSchemaModel

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

  before_save :strip_urls

  validates_attachment_content_type :dataset,
      :content_type => ['application/x-gzip','application/x-tar','text/xml'],
      :message => "dataset file is not a valid file type"

  validates_presence_of :title
  validates_presence_of :subject
  validates_presence_of :license_id
  validates_presence_of :resource_created_at
  validates_presence_of :refresh_period_hours, :if => :accesspoint_url_provided?

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

  # trying to change it to memcache got error after reload a page
  def self.iucn
    cached('iucn') do
      Agent.iucn.user.content_partner.resources.last
    end
  end

  def self.ligercat
    cached('ligercat') do
      Agent.boa.user.content_partner.resources[0]
    end
  end

  def status_label
    (resource_status.nil?) ? I18n.t(:content_partner_resource_resource_status_new) : resource_status.label
  end

  def latest_unpublished_harvest_event
    HarvestEvent.find(:first, :conditions => ["published_at IS NULL AND completed_at IS NOT NULL AND resource_id = ?", id],
                              :limit => 1,
                              :order => 'completed_at desc')
  end

  # custom method to eager load latest_published_harvest_event
  def self.add_latest_published_harvest_event!(resources)
    resources_ids = resources.collect(&:id)
    return if resources_ids.empty?
    latest_published_harvest_events = HarvestEvent.all(
      :conditions => [
        'published_at IS NOT NULL AND completed_at IS NOT NULL AND resource_id IN (:resources_ids)',
        { :resources_ids => resources_ids }
      ],
      :group => 'resource_id',
      :order => 'published_at DESC')
    resources.each do |resource|
      resource.latest_published_harvest_event = latest_published_harvest_events.select{|he| he.resource_id == resource.id}.first
    end
  end

#  TODO: Added eager loading self.add_latest_published_harvest_event!(resources), how to stop this querying if already eager loaded
#  def latest_published_harvest_event
#    HarvestEvent.find(:first, :conditions => ["published_at IS NOT NULL AND completed_at IS NOT NULL AND resource_id = ?", id],
#                              :limit => 1,
#                              :order => 'published_at desc')
#  end

  def latest_harvest_event
    HarvestEvent.find(:first, :limit => 1, :order => 'id desc', :conditions => ["resource_id = ?", id])
  end

  def all_harvest_events
    HarvestEvent.find(:first, :conditions => ["resource_id = ?", id],
                              :order => 'completed_at desc')
  end

  def validate
    if accesspoint_url.blank? && dataset_file_name.blank?
       errors.add_to_base("You must either provide a URL or upload a resource file")
    elsif dataset_file_name.blank? && !accesspoint_url.blank?  # gave a URL
      accesspoint_url.strip!
      if !accesspoint_url.match(/\.xml(\.gz|\.gzip)?/)  # URL is not .xml, .xml.gz, .xml.gzip
        errors.add_to_base("The resource file URL must be .xml or .xml.gz(ip)")
      elsif !EOLWebService.url_accepted?(accesspoint_url)  # URL doesn't return 200
        errors.add_to_base("The resource file URL is not valid")
      end
    end

    unless dwc_archive_url.blank?
      dwc_archive_url.strip!
      if !dwc_archive_url.match(/(\.tar\.(gz|gzip)|.tgz)/)  # dwca url not a .tar.gz, .tar.gzip, .tgz
        errors.add_to_base("The Darwin Core Archive must be a tar/gzip file")
      elsif !EOLWebService.url_accepted?(dwc_archive_url)  # dwca url does't return 200
        errors.add_to_base("The Darwin Core Archive URL is not valid")
      end
    end
  end

  # vet or unvet entire resource (0 = unknown, 1 = vet)
  def set_vetted_status(vetted)
    set_to_state = EOLConvert.to_boolean(vetted) ? Vetted.trusted.id : Vetted.unknown.id

    # update the vetted_id of all data_objects associated with the latest
    SpeciesSchemaModel.connection.execute("update harvest_events he straight_join data_objects_harvest_events dohe on (he.id=dohe.harvest_event_id) straight_join data_objects do on (dohe.data_object_id=do.id) set do.vetted_id = #{set_to_state} where do.vetted_id = 0 and he.resource_id = #{self.id}")

    if set_to_state == Vetted.trusted.id && !hierarchy.nil?
      # update the vetted_id of all concepts associated with this resource - only vet them never unvet them
      SpeciesSchemaModel.connection.execute("UPDATE hierarchy_entries he JOIN taxon_concepts tc ON (he.taxon_concept_id=tc.id) SET tc.vetted_id=#{Vetted.trusted.id} WHERE hierarchy_id=#{hierarchy.id}")
    end

    self.vetted=vetted

    true
  end

  def upload_resource_to_content_master(application_server_url)
    resource_status = ResourceStatus.uploaded if accesspoint_url.blank?

    file_path = (accesspoint_url.blank? ? application_server_url + $DATASET_UPLOAD_PATH + id.to_s + "."+ dataset_file_name.split(".")[-1] : accesspoint_url)
    parameters = 'function=upload_resource&resource_id=' + id.to_s + '&file_path=' + file_path
    begin
      response = EOLWebService.call(:parameters => parameters)
    rescue
      ErrorLog.create(:url  => $WEB_SERVICE_BASE_URL, :exception_name  => "content provider dataset service has an error") if $ERROR_LOGGING
      resource_status = ResourceStatus.upload_failed
    end
    if response.nil? || response.blank?
      ErrorLog.create(:url  => $WEB_SERVICE_BASE_URL, :exception_name  => "content provider dataset service timed out") if $ERROR_LOGGING
      resource_status = ResourceStatus.upload_failed
    else
      response = Hash.from_xml(response)
      # response is an error
      if response["response"].key? "error"
        error = response["response"]["error"]
        ErrorLog.create(:url=>$WEB_SERVICE_BASE_URL,:exception_name=>"content partner dataset service failed", :backtrace=>parameters) if $ERROR_LOGGING
        notes = error
        resource_status = ResourceStatus.upload_failed
      # else set status to response
      elsif response["response"].key? "status"
        status = response["response"]["status"]
        resource_status = ResourceStatus.send(status.downcase.gsub(" ","_"))
        if response["response"].key? "error"
          error = response["response"]["error"]
          ErrorLog.create(:url=>$WEB_SERVICE_BASE_URL,:exception_name=>"content partner dataset service failed", :backtrace=>parameters) if $ERROR_LOGGING
          notes = error if status.strip == 'Validation failed'
        end
      end
    end
    self.save!
    return resource_status
  end

private
  def accesspoint_url_provided?
    !accesspoint_url.blank?
  end

  def strip_urls
    accesspoint_url.strip! if accesspoint_url
    dwc_archive_url.strip! if dwc_archive_url
  end
end

