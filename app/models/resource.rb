class Resource < SpeciesSchemaModel

  # This class represents some notion of a set of data.  For example, a collection of images of butterflies.

  belongs_to :service_types
  belongs_to :license
  belongs_to :language
  belongs_to :resource_status
  belongs_to :hierarchy

  has_many :agents, :through => :agents_resources
  has_many :agents_resources
  has_many :resources_taxa
  has_many :harvest_events


  has_and_belongs_to_many :taxa

  has_attached_file :dataset,
    :path => $DATASET_UPLOAD_DIRECTORY,
    :url => $DATASET_URL_PATH

  validates_attachment_content_type :dataset, 
      :content_type => ['application/x-gzip','application/x-tar','text/xml'],
      :message => "dataset file is not a valid file type"

  validates_presence_of :title, :message => "can't be blank"  
  validates_presence_of :subject, :message => "can't be blank"
  validates_presence_of :license_id, :message => "must be indicated"

  # trying to change it to memcache got error after reload a page
  def self.iucn
    Rails.cache.fetch('resources/iucn') do
      Agent.iucn.resources[0]
    end
  end

  def status_label
    (resource_status.nil?) ? "Created" : resource_status.label
  end

  def latest_unpublished_harvest_event
    HarvestEvent.find(:first, :conditions => ["published_at IS NULL AND completed_at IS NOT NULL AND resource_id = ?", id],
                              :limit => 1,
                              :order => 'completed_at desc')
  end

  def latest_published_harvest_event
    HarvestEvent.find(:first, :conditions => ["published_at IS NOT NULL AND completed_at IS NOT NULL AND resource_id = ?", id],
                              :limit => 1,
                              :order => 'published_at desc')
  end

  def all_harvest_events
    HarvestEvent.find(:first, :conditions => ["resource_id = ?", id],
                              :order => 'completed_at desc')
  end

  def validate
    if accesspoint_url.blank? && dataset_file_name.blank?
       errors.add_to_base("You must either provide a URL or upload a resource file")   
    elsif dataset_file_name.blank? && !accesspoint_url.blank? && !EOLWebService.valid_url?(accesspoint_url)
       errors.add_to_base("The resource data URL is not valid")
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

end

