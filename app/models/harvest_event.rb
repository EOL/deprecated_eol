class HarvestEvent < ActiveRecord::Base

  belongs_to :resource
  has_many :data_objects_harvest_events
  has_many :data_objects, through: :data_objects_harvest_events
  has_many :harvest_events_hierarchy_entries
  has_and_belongs_to_many :hierarchy_entries

  validates_inclusion_of :publish, in: [false], unless: :publish_is_allowed?

  scope :incomplete, -> { where(completed_at: nil) }

  def self.last_incomplete_resource
    incomplete.includes(:resource).last.resource
  end

  # harvest event ids for the last harvest event of every resource
  def self.latest_ids
    @latest_ids ||= HarvestEvent.maximum('id', group: :resource_id).values
  end

  def self.last_published
    last_published=HarvestEvent.find(:all, conditions: "published_at != 'null'", limit: 1, order: 'published_at desc')
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
      joins: "JOIN #{DataObjectsHarvestEvent.full_table_name} dohe ON (curator_activity_logs.data_object_guid=dohe.guid)",
      conditions: "curator_activity_logs.activity_id IN (#{Activity.trusted.id}, #{Activity.untrusted.id}, #{Activity.hide.id}, #{Activity.show.id}) AND curator_activity_logs.changeable_object_type_id IN (#{ChangeableObjectType.data_object_scope.join(',')}) AND dohe.harvest_event_id = #{id} #{date_condition}",
      select: 'id')

    curator_activity_logs = CuratorActivityLog.find_all_by_id(curator_activity_logs.collect{ |ah| ah.id },
      include: [ :user, :comment, :activity, :changeable_object_type, :data_object  ],
      select: {
        users: [ :id, :given_name, :family_name ],
        comments: [ :id, :user_id, :body ],
        data_objects: [ :id, :object_cache_url, :source_url, :data_type_id, :published, :created_at ] })

    data_objects = curator_activity_logs.collect(&:data_object)
    DataObject.replace_with_latest_versions!(data_objects, check_only_published: true, language_id: Language.english.id)
    includes = [ { data_objects_hierarchy_entries: [ { hierarchy_entry: [ :name, :hierarchy, :taxon_concept ] }, :vetted, :visibility ] } ]
    includes << { all_curated_data_objects_hierarchy_entries: [ { hierarchy_entry: [ :name, :hierarchy, :taxon_concept ] }, :vetted, :visibility, :user ] }
    DataObject.preload_associations(data_objects, includes)
    DataObject.preload_associations(data_objects, :users_data_object)
    curator_activity_logs.each do |cal|
      if d = data_objects.detect{ |o| cal.data_object.guid == o.guid }
        cal.data_object = d
      end
    end

    curator_activity_logs.sort_by{ |ah| Invert(ah.id) }
  end

  def publish_is_allowed?
    self.published_at.blank? && !self.completed_at.blank? && self == self.resource.latest_harvest_event
  end

  def publish_pending?
    self.published_at.blank? && self.publish?
  end

  def destroy_everything
    Rails.logger.error("** Destroying HarvestEvent #{id}")
    data_objects.each do |dato|
      dato.destroy_everything
      dato.destroy
    end
    DataObjectsHarvestEvent.where(harvest_event_id: id).destroy_all
    hierarchy_entries.each do |entry|
      entry.destroy_everything
      name = Name.find(entry.name_id)
      hierarchy = Hierarchy.find(entry.hierarchy_id)
      entry.destroy
      entry.taxon_concept.destroy if
        entry.taxon_concept.hierarchy_entries.blank?
      name.destroy if name.hierarchy_entries.blank?
      hierarchy.destroy if hierarchy.hierarchy_entries.blank?
    end
    # This next operation can fail because of table locks...
    begin
      HarvestEventsHierarchyEntry.delete_all(["harvest_event_id = ?", id])
    rescue ActiveRecord::StatementInvalid => e
      # This is not *fatal*, it's just unfortunate. Probably because we're harvesting, but waiting for harvests to finish is not possible.
      Rails.logger.error("** Unable to delete from HarvestEventsHierarchyEntry where harvest_event_id = #{id} (#{e.message})")
    end
    Rails.logger.error("** Destroyed HarvestEvent #{id}")
  end

end
