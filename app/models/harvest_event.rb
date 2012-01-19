class HarvestEvent < SpeciesSchemaModel

  belongs_to :resource
  has_many :data_objects_harvest_events
  has_many :data_objects, :through => :data_objects_harvest_events
  has_many :harvest_events_hierarchy_entries
  has_and_belongs_to_many :hierarchy_entries

  before_destroy :remove_related_data_objects

  validates_inclusion_of :publish, :in => [false], :unless => :publish_is_allowed?

  # harvest event ids for the last harvest event of every resource
  def self.latest_ids
    @latest_ids ||= HarvestEvent.maximum('id', :group => :resource_id).values
  end

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
    resource.content_partner
  end

  def curated_data_objects(params = {})
    year = params[:year] || nil
    month = params[:month] || nil

    unless year || month
      year = Time.now.year if year.nil?
      month = Time.now.month if month.nil?
    end

    year = Time.now.year if year.nil?
    month = 0 if month.nil?
    lower_date_range = "#{year}-#{month}-00"
    if month.to_i == 0
      upper_date = Time.local(year, 1) + 1.year
      upper_date_range = "#{upper_date.year}-#{upper_date.month}-00"
    else
      upper_date = Time.local(year, month) + 1.month
      upper_date_range = "#{upper_date.year}-#{upper_date.month}-00"
    end

    date_condition = ""
    if lower_date_range
      date_condition = "AND curator_activity_logs.updated_at BETWEEN '#{lower_date_range}' AND '#{upper_date_range}'"
    end

    curator_activity_logs = CuratorActivityLog.find(:all,
      :joins => "JOIN #{DataObjectsHarvestEvent.full_table_name} dohe ON (curator_activity_logs.object_id=dohe.data_object_id)",
      :conditions => "curator_activity_logs.activity_id IN (#{Activity.trusted.id}, #{Activity.untrusted.id}, #{Activity.inappropriate.id}, #{Activity.delete.id}) AND curator_activity_logs.changeable_object_type_id = #{ChangeableObjectType.data_object.id} AND dohe.harvest_event_id = 2 #{date_condition}",
      :select => 'id')

    curator_activity_logs = CuratorActivityLog.find_all_by_id(curator_activity_logs.collect{ |ah| ah.id },
      :include => [ :user, :comment, :activity, :changeable_object_type,
        { :data_object => { :hierarchy_entries => :name } } ],
      :select => {
        :curator_activity_logs => :updated_at,
        :users => [ :given_name, :family_name ],
        :comments => :body,
        :data_objects => [:object_cache_url, :source_url, :data_type_id ],
        :hierarchy_entries => [ :published, :visibility_id, :taxon_concept_id ],
        :names => :string })
    curator_activity_logs.sort_by{ |ah| Invert(ah.id) }
  end

  def publish_is_allowed?
    self.published_at.blank? && !self.completed_at.blank? && self == self.resource.latest_harvest_event
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
