class HarvestEvent < SpeciesSchemaModel
  belongs_to :resource
  has_many :data_objects_harvest_events
  has_many :data_objects, :through => :data_objects_harvest_events
  has_and_belongs_to_many :taxa

  before_destroy :remove_related_data_objects
  
  def publish
    published = true
    begin
      SpeciesSchemaModel.transaction do
        is_new_harvest_event = !DataObject.find_by_sql("select d.id from data_objects d join data_objects_harvest_events dh on (d.id=dh.data_object_id) where dh.harvest_event_id = #{self.id} and d.visibility_id = #{Visibility.preview.id} limit 1").blank?
        make_visible if is_new_harvest_event

        self.resource.unpublish(false)
        
        delete_upstream_harvests
        
        SpeciesSchemaModel.connection.execute("update data_objects, data_objects_harvest_events set data_objects.published = 1 where data_objects.id = data_objects_harvest_events.data_object_id and data_objects_harvest_events.harvest_event_id = #{self.id}")
        
        self.published_at = Time.now
        self.save!
      end
    rescue
      published = false
    end
    published
  end

  def make_visible 
    # change all data objects for this harvest event that are currently visibility=preview to visibility=visible
    SpeciesSchemaModel.connection.execute("update data_objects d, data_objects_harvest_events dh set d.visibility_id = #{Visibility.visible.id} where d.visibility_id = #{Visibility.preview.id} and d.id = dh.data_object_id and dh.harvest_event_id = #{self.id}")
     
    #find inappropriate and invisible objects connected to harvest
    data = SpeciesSchemaModel.connection.select_rows("select do.guid, MAX(do.id), do.visibility_id from data_objects_harvest_events dohe join data_objects do on (dohe.guid=do.guid) where dohe.status_id=2 and do.id!=dohe.data_object_id and do.visibility_id IN (#{Visibility.invisible.id},#{Visibility.inappropriate.id}) GROUP BY do.guid")  
    data.each do |d|
      query = "update data_objects do, data_objects_harvest_events dh set do.visibility_id = #{d[2]} where dh.guid = '#{d[0]}' and do.guid = dh.guid and dh.harvest_event_id = #{self.id}"
      SpeciesSchemaModel.connection.execute(query)
    end
  end

  def make_invisible 
    # change all data objects for this harvest event that are currently not visibility=inappropriate to visibility=invisible
    SpeciesSchemaModel.connection.execute("update data_objects d, data_objects_harvest_events dh set d.visibility_id = #{Visibility.invisible.id} where d.visibility_id <> #{Visibility.inappropriate.id} and d.id = dh.data_object_id and dh.harvest_event_id = #{self.id}")
  end

  def self.last_published
    last_published=HarvestEvent.find(:all,:conditions=>"published_at <> 'null'",:limit=>1,:order=>'published_at desc')
    return (last_published.blank? ? nil : last_published[0])
  end
  
  protected

  def delete_upstream_harvests
    he = self.resource.harvest_events
    if self != he.last
      harvest_event_delete_index = he.index(self) + 1
      harvests_to_delete = self.resource.harvest_events[harvest_event_delete_index..(he.size-1)]
      harvests_to_delete.each do |harvest_event|
        harvest_event.destroy
      end
    end
  end
  
  def remove_related_data_objects

    # get data objects
    data_objects=SpeciesSchemaModel.connection.select_values("SELECT do.id FROM data_objects do JOIN data_objects_harvest_events dohe ON dohe.data_object_id=do.id WHERE dohe.status_id != #{Status.unchanged.id} and dohe.harvest_event_id=#{self.id}").join(",")
     
    #remove data_objects_taxa
    SpeciesSchemaModel.connection.execute("DELETE FROM data_objects_taxa WHERE data_object_id IN (#{data_objects})")
    
    #remove data objects that have been inserted or updated
    SpeciesSchemaModel.connection.execute("DELETE FROM data_objects WHERE id in (#{data_objects})")
    
    #remove data_objects_harvest_events
    DataObjectsHarvestEvent.delete_all(['harvest_event_id=?',self.id])

    #remove harvest_events_taxa
    HarvestEventsTaxon.delete_all(['harvest_event_id=?',self.id])
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

