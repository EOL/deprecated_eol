class HarvestEvent < SpeciesSchemaModel

  belongs_to :resource
  has_many :data_objects_harvest_events
  has_many :data_objects, :through => :data_objects_harvest_events
  has_and_belongs_to_many :hierarchy_entries

  before_destroy :remove_related_data_objects

  def self.last_published
    last_published=HarvestEvent.find(:all,:conditions=>"published_at != 'null'",:limit=>1,:order=>'published_at desc')
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
  
  def curated_data_objects(params = {})
    year = params[:year] || nil
    month = params[:month] || nil
    
    if year || month
      year = Time.now.year if year.nil?
      month = 0 if month.nil?
      lower_date_range = "#{year}-#{month}-00"
      if month == 0
        upper_date = Time.local(year, 1) + 1.year
        upper_date_range = "#{upper_date.year}-#{upper_date.month}-00"
      else
        upper_date = Time.local(year, month) + 1.month
        upper_date_range = "#{upper_date.year}-#{upper_date.month}-00"
      end
    end
    
    query = "SELECT ah.object_id data_object_id, awo.action_code action_code, u.id curator_user_id,
    u.given_name, u.family_name, ah.updated_at, ah.user_id, ah.id actions_history_id, dt.label data_type_label,
    do.object_cache_url, do.source_url, he.taxon_concept_id, n.string scientific_name
    FROM #{ActionWithObject.full_table_name} awo
    JOIN #{ActionsHistory.full_table_name} ah ON (ah.action_with_object_id=awo.id)
    JOIN #{User.full_table_name} u ON (ah.user_id=u.id)
    JOIN data_objects_harvest_events dohe ON (dohe.data_object_id=ah.object_id)
    JOIN data_objects do ON (dohe.data_object_id=do.id)
    JOIN data_types dt ON (do.data_type_id=dt.id)
    LEFT JOIN (
       data_objects_hierarchy_entries dohent
       JOIN hierarchy_entries he ON (dohent.hierarchy_entry_id=he.id)
       JOIN names n ON (he.name_id=n.id)
      ) ON (do.id=dohent.data_object_id)
    WHERE ah.changeable_object_type_id = #{ChangeableObjectType.data_object.id}
    AND dohe.harvest_event_id = #{self.id}
    AND awo.id in (#{ActionWithObject.trusted.id}, #{ActionWithObject.untrusted.id}, #{ActionWithObject.inappropriate.id}, #{ActionWithObject.delete.id})"
    if lower_date_range
      query += " AND ah.updated_at BETWEEN '#{lower_date_range}' AND '#{upper_date_range}'"
    end
    results = connection.execute(query).all_hashes
    results.group_hashes_by!('actions_history_id')
    results.sort{|a,b| b['actions_history_id'].to_i <=> a['actions_history_id'].to_i}
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
