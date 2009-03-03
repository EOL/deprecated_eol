class Resource < SpeciesSchemaModel
  
  # This class represents some notion of a set of data.  For example, a collection of images of butterflies.

  belongs_to :service_types
  belongs_to :license
  belongs_to :language
  belongs_to :resource_status

  has_many :agents, :through => :agents_resources
  has_many :agents_resources
  has_many :resources_taxa
  has_many :harvest_events
  
  has_and_belongs_to_many :taxa
  
#  has_many :agents_resources, :class_name => 'AgentsResource' #, :foreign_key => :foreign_key

  has_attached_file :dataset,
    :path => $DATASET_UPLOAD_DIRECTORY,
    :url => $DATASET_URL_PATH

  validates_attachment_content_type :dataset, 
      :content_type => ['application/x-gzip','application/x-tar','text/xml'],
      :message => "dataset file is not a valid file type"
             
  validates_presence_of :title, :message => "can't be blank"  
  validates_presence_of :subject, :message => "can't be blank"
  validates_presence_of :license_id, :message => "must be indicated"

  def self.iucn
    Rails.cache.fetch(:iucn_resource) do
      @@iucn_resource = Resource.find_by_title('Initial IUCN Import')
    end
  end
  
  def status_label
    (resource_status.nil?) ? "Pending" : resource_status.label
  end
  # vet or unvet entire resource (0 = unknown, 1 = vet)
  def set_vetted_status(vetted) 
    set_to_state = EOLConvert.to_boolean(vetted) ? Vetted.trusted.id : Vetted.unknown.id
    SpeciesSchemaModel.connection.execute("update data_objects d, data_objects_harvest_events dh, harvest_events h set d.vetted_id = #{set_to_state} where d.curated = 0 and  d.id = dh.data_object_id and dh.harvest_event_id = h.id and h.resource_id =  #{self.id}")
    self.vetted=vetted
    true
  end

  def taxon_concept_ids
    SpeciesSchemaModel.connection.select_values("select distinct tc.id from resources r join harvest_events h on r.id=h.resource_id join harvest_events_taxa ht on h.id=ht.harvest_event_id join taxa t on t.id=ht.taxon_id join hierarchy_entries he on he.id=t.hierarchy_entry_id join taxon_concepts tc on tc.id=he.taxon_concept_id where r.id=#{self.id.to_s}")
  end
  
  def hide_latest_harvest
    self.harvest_events.last.make_invisible
  end
  
  def validate
    if accesspoint_url.blank? && dataset_file_name.blank?
       errors.add_to_base("You must either provide a URL or upload a resource file")   
    elsif dataset_file_name.blank? && !accesspoint_url.blank? && !EOLWebService.valid_url?(accesspoint_url)
       errors.add_to_base("The resource data URL is not valid")
    end
  end
  
  def publish(a_harvest_event = self.harvest_events.last)
    published = false
    if self.resource_status = ResourceStatus.processed
      published = a_harvest_event.publish
      self.resource_status = ResourceStatus.published if published
    end
    published
  end
  
  def unpublish(change_resource_status = true)
    unpublished = false
    SpeciesSchemaModel.connection.execute("update data_objects d, data_objects_harvest_events dh, harvest_events h set d.published = 0 where d.published = 1 and  d.id = dh.data_object_id and dh.harvest_event_id = h.id and h.resource_id =  #{self.id}")
    self.update_attribute(:resource_status_id,ResourceStatus.processed.id) if change_resource_status
    unpublished = true
  end
    
  
end
# == Schema Info
# Schema version: 20080923175821
#
# Table name: resources
#
#  id                     :integer(4)      not null, primary key
#  language_id            :integer(2)
#  license_id             :integer(1)      not null
#  resource_status_id     :integer(4)
#  service_type_id        :integer(4)      not null, default(1)
#  accesspoint_url        :string(255)
#  bibliographic_citation :string(400)
#  dataset_content_type   :string(255)
#  dataset_file_name      :string(255)
#  dataset_file_size      :integer(4)
#  description            :string(255)
#  logo_url               :string(255)
#  metadata_url           :string(255)
#  refresh_period_hours   :integer(2)
#  resource_set_code      :string(255)
#  rights_holder          :string(255)
#  rights_statement       :string(400)
#  service_version        :string(255)
#  subject                :string(255)     not null
#  title                  :string(255)     not null
#  created_at             :timestamp       not null
#  harvested_at           :datetime
#  resource_created_at    :datetime
#  resource_modified_at   :datetime

# == Schema Info
# Schema version: 20081002192244
#
# Table name: resources
#
#  id                     :integer(4)      not null, primary key
#  language_id            :integer(2)
#  license_id             :integer(1)      not null
#  resource_status_id     :integer(4)
#  service_type_id        :integer(4)      not null, default(1)
#  accesspoint_url        :string(255)
#  bibliographic_citation :string(400)
#  dataset_content_type   :string(255)
#  dataset_file_name      :string(255)
#  dataset_file_size      :integer(4)
#  description            :string(255)
#  logo_url               :string(255)
#  metadata_url           :string(255)
#  refresh_period_hours   :integer(2)
#  resource_set_code      :string(255)
#  rights_holder          :string(255)
#  rights_statement       :string(400)
#  service_version        :string(255)
#  subject                :string(255)     not null
#  title                  :string(255)     not null
#  created_at             :timestamp       not null
#  harvested_at           :datetime
#  resource_created_at    :datetime
#  resource_modified_at   :datetime

# == Schema Info
# Schema version: 20081020144900
#
# Table name: resources
#
#  id                     :integer(4)      not null, primary key
#  language_id            :integer(2)
#  license_id             :integer(1)      not null
#  resource_status_id     :integer(4)
#  service_type_id        :integer(4)      not null, default(1)
#  accesspoint_url        :string(255)
#  auto_publish           :boolean(1)      not null
#  bibliographic_citation :string(400)
#  dataset_content_type   :string(255)
#  dataset_file_name      :string(255)
#  dataset_file_size      :integer(4)
#  description            :string(255)
#  logo_url               :string(255)
#  metadata_url           :string(255)
#  refresh_period_hours   :integer(2)
#  resource_set_code      :string(255)
#  rights_holder          :string(255)
#  rights_statement       :string(400)
#  service_version        :string(255)
#  subject                :string(255)     not null
#  title                  :string(255)     not null
#  vetted                 :boolean(1)      not null
#  created_at             :timestamp       not null
#  harvested_at           :datetime
#  resource_created_at    :datetime
#  resource_modified_at   :datetime

