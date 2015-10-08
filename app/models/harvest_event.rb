class HarvestEvent < ActiveRecord::Base

  belongs_to :resource
  has_many :data_objects_harvest_events
  has_many :data_objects, through: :data_objects_harvest_events
  has_many :harvest_events_hierarchy_entries
  has_and_belongs_to_many :hierarchy_entries

  validates_inclusion_of :publish, in: [false], unless: :publish_is_allowed?

  scope :incomplete, -> { where(completed_at: nil) }
  scope :pending, -> { where(publish: true, published_at: nil) }
  scope :published, -> { where("published_at IS NOT NULL") }
  scope :complete, -> { where("completed_at IS NOT NULL") }

  def self.last_incomplete_resource
    return nil if incomplete.count < 1
    incomplete.includes(:resource).last.resource
  end

  # harvest event ids for the last harvest event of every resource
  def self.latest_ids
    @latest_ids ||= HarvestEvent.maximum('id', group: :resource_id).values
  end

  def self.last_published
    published.order("published_at DESC").first
  end

  # Seriously? This should be an instance method. Not even; it should be a
  # relationship. What the heck was this person thinking?  (Sorry, but:
  # seriously! Welcome to Rails.)
  def self.data_object_ids_from_harvest(harvest_event_id)
    query = "SELECT dohe.data_object_id
    FROM harvest_events he
    JOIN data_objects_harvest_events dohe ON he.id = dohe.harvest_event_id
    WHERE he.id = #{harvest_event_id}"
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

  # TODO: THIS IS HORRIBLE!  AUGH!
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

  def complete?
    self[:completed_at]
  end

  def latest?
    self[:id] == resource.latest_harvest_event.id
  end

  def published?
    self[:published_at]
  end

  def publish_is_allowed?
    ! published? &&
      complete &&
      latest?
  end

  def publish_pending?
    ! published? && self.publish?
  end

  def preserve_curations
    EOL.log_call
    previous = resource.latest_published_harvest_event_uncached
    if previous.nil?
      EOL.log("First harvest! Nothing to preserve.")
      return
    end
    # TODO:
    # $last_harvest = new HarvestEvent($last_published_harvest_event_id);
    # // make sure its in the same resource
    # if($last_harvest->resource_id != $this->resource_id) return false;
    # // make sure this is newer
    # if($last_harvest->id > $this->id) return false;
    #
    # $outfile = $GLOBALS['db_connection']->select_into_outfile("
    #     SELECT do_current.id, dohent_previous.visibility_id, dohent_previous.hierarchy_entry_id
    #     FROM
    #         (data_objects_harvest_events dohe_previous
    #         JOIN data_objects do_previous ON (dohe_previous.data_object_id=do_previous.id)
    #         JOIN data_objects_hierarchy_entries dohent_previous ON (dpo_previous.id=dohent_previous.data_object_id))
    #     JOIN
    #         (data_objects_harvest_events dohe_current
    #         JOIN data_objects do_current ON (dohe_current.data_object_id=do_current.id))
    #     ON (dohe_previous.guid=dohe_current.guid AND dohe_previous.data_object_id!=dohe_current.data_object_id)
    #     WHERE dohe_previous.harvest_event_id=$last_harvest->id
    #     AND dohe_current.harvest_event_id=$this->id
    #     AND dohent_previous.visibility_id IN (".Visibility::invisible()->id.")");
    #
    # if (!($FILE = fopen($outfile, "r")))
    # {
    #   debug(__CLASS__ .":". __LINE__ .": Couldn't open file: " . $outfile);
    #   return;
    # }
    # while(!feof($FILE))
    # {
    #     if($line = fgets($FILE, 4096))
    #     {
    #         $values = explode("\t", trim($line));
    #         $data_object_id = $values[0];
    #         $visibility_id = $values[1];
    #         $hierarchy_entry_id = $values[2];
    #         $GLOBALS['db_connection']->update("UPDATE data_objects_hierarchy_entries SET visibility_id=$visibility_id WHERE data_object_id=$data_object_id AND hierarchy_entry_id=$hierarchy_entry_id");
    #     }
    # }
    # fclose($FILE);
    # unlink($outfile);
  end

  def destroy_everything
    Rails.logger.error("** Destroying HarvestEvent #{id}")
    Rails.logger.error("   #{data_objects.count} DataObjects...")
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
