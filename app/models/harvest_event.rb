class HarvestEvent < SpeciesSchemaModel
  belongs_to :resource
  has_many :data_objects_harvest_events
  has_many :data_objects, :through => :data_objects_harvest_events
  has_and_belongs_to_many :hierarchy_entries
  
  before_destroy :remove_related_data_objects
  
  
  def self.last_published
    last_published=HarvestEvent.find(:all,:conditions=>"published_at <> 'null'",:limit=>1,:order=>'published_at desc')
    return (last_published.blank? ? nil : last_published[0])
  end
  
  
  def self.data_object_ids_from_harvest(harvest_event_id)
    query = "Select data_objects_harvest_events.data_object_id
    From harvest_events
    Inner Join data_objects_harvest_events ON harvest_events.id = data_objects_harvest_events.harvest_event_id
    Where harvest_events.id = #{harvest_event_id}"    
    rset = self.find_by_sql [query]
    arr=[]
    for fld in rset
	    arr << fld["data_object_id"]
    end
    return arr
  end
  
  
  
  protected
  
  def remove_related_data_objects
    # get data objects
    data_objects=SpeciesSchemaModel.connection.select_values("SELECT do.id FROM data_objects do JOIN data_objects_harvest_events dohe ON dohe.data_object_id=do.id WHERE dohe.status_id != #{Status.unchanged.id} and dohe.harvest_event_id=#{self.id}").join(",")
     
    #remove data_objects_hierarchy_entries
    SpeciesSchemaModel.connection.execute("DELETE FROM data_objects_hierarchy_entries WHERE data_object_id IN (#{data_objects})")
    
    #remove data objects that have been inserted or updated
    SpeciesSchemaModel.connection.execute("DELETE FROM data_objects WHERE id in (#{data_objects})")
    
    #remove data_objects_harvest_events
    DataObjectsHarvestEvent.delete_all(['harvest_event_id=?',self.id])

    #remove harvest_events_taxa
    HarvestEventsHierarchyEntry.delete_all(['harvest_event_id=?',self.id])
  end
  
end

# == Schema Info
# Schema version: 20081020144900
#
# Table name: harvest_events
#
#  id           :integer(1)      not null, primary key
#  resource_id  :string(100)     not null
#  began_at     :timestamp       not null
#  completed_at :timestamp
#  published_at :timestamp

