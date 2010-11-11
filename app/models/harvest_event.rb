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
    query = "Select dohe.data_object_id
    From harvest_events he
    Join data_objects_harvest_events dohe ON he.id = dohe.harvest_event_id
    Where he.id = #{harvest_event_id}"    
    rset = self.find_by_sql [query]
    arr=[]
    for fld in rset
	    arr << fld["data_object_id"]
    end
    return arr
  end
  
  def content_partner
    resource.agents_resources.each do |ar|
      if ar.resource_agent_role == ResourceAgentRole.content_partner_upload_role
        return ar.agent.content_partner
      end
    end
    return nil
  end

  def taxa_contributed(he_id)
    SpeciesSchemaModel.connection.execute(
      "SELECT n.string scientific_name, he.taxon_concept_id, (dohe.data_object_id IS NOT null) has_data_object
         FROM harvest_events_hierarchy_entries hehe
           JOIN hierarchy_entries he ON (hehe.hierarchy_entry_id = he.id)
           JOIN names n ON (he.name_id = n.id)
           LEFT JOIN data_objects_hierarchy_entries dohe ON (hehe.hierarchy_entry_id = dohe.hierarchy_entry_id)
         WHERE hehe.harvest_event_id=#{he_id.to_i}
         GROUP BY he.taxon_concept_id
         ORDER BY (dohe.data_object_id IS NULL), n.string")
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
