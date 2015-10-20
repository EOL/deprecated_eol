class HarvestEvent < ActiveRecord::Base

  belongs_to :resource

  has_one :hierarchy, through: :resource

  has_many :data_objects_harvest_events
  has_many :data_objects, through: :data_objects_harvest_events
  has_many :harvest_events_hierarchy_entries

  has_and_belongs_to_many :hierarchy_entries

  validates_inclusion_of :publish, in: [false], unless: :publish_is_allowed?

  scope :incomplete, -> { where(completed_at: nil) }
  scope :pending, -> { where(publish: true, published_at: nil) }
  scope :published, -> { where("published_at IS NOT NULL") }
  scope :complete, -> { where("completed_at IS NOT NULL") }
  scope :unpublished, -> { where("published_at IS NULL") }

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
      if d = data_objects.detect { |o| cal.data_object.guid == o.guid }
        cal.data_object = d
      end
    end
    curator_activity_logs.sort_by { |ah| Invert(ah.id) }
  end

  # TODO: move
  def previous_harvest
    HarvestEvent.where(resource_id: resource_id).where(["id < ?", id]).last
  end

  # TODO: move NOTE: Can't use an association here, sadly, because of resource
  # being in the middle.
  def hierarchy_entries_with_ancestors
    hierarchy.hierarchy_entries
  end

  # TODO: move this to hierarchy.
  def merge_matching_taxon_concepts
    EOL.log_call
    Hierarchy::Relator.relate(hierarchy, entry_ids: new_hierarchy_entry_ids)
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

  def publish_data_objects
    count = data_objects.where(published: false).update_all(published: true)
    update_attributes(published_at: Time.now)
    count
  end

  # NOTE: this also makes them visible, and it also publishes associated TCs and
  # synonyms. TODO: that's misleading. Rename/breakup. TODO: pluck may be
  # inefficient here, we could try joins and/or associations. TODO: the
  # #publish_and_show_he_parents method is more efficient, and could have been
  # written to do this as well.
  def publish_hierarchy_entries
    hierarchy_entries.update_all(published: true,
      visibility_id: Visibility.get_visible.id)
    TaxonConcept.where(id: hierarchy_entries.pluck(:taxon_concept_id),
      published: false).update_all(published: true)
    Synonym.where(hierarchy_entry_id: hierarchy_entries.pluck(:id),
      published: false).update_all(published: true)
    publish_and_show_hierarchy_entry_parents
  end

  # TODO: this would be unnecessary if, during a harvest, we just looked for the
  # previous harvest event's associations and honored those visibilities.
  def preserve_invisible
    EOL.log_call
    previously = resource.latest_published_harvest_event_uncached
    if previously.nil?
      EOL.log("First harvest! Nothing to preserve.")
      return
    end
    # NOTE: Ick. This actually runs moderately fast, but... ick. TODO - This
    # would be much simpler if we had the harvest_event_id in the dohe table...
    # or something like that...
    invisible_ids = DataObjectsHierarchyEntry.invisible.
      joins("JOIN data_objects_harvest_events ON "\
        "(data_objects_harvest_events.data_object_id = "\
        "data_objects_hierarchy_entries.data_object_id AND "\
        "data_objects_harvest_events.harvest_event_id = #{previously.id})").
      pluck(:data_object_id)
    DataObjectsHierarchyEntry.
      joins("JOIN data_objects_harvest_events ON "\
        "(data_objects_harvest_events.data_object_id = "\
        "data_objects_hierarchy_entries.data_object_id AND "\
        "data_objects_harvest_events.harvest_event_id = #{id})").
      update_all(visibility_id: Visibility.get_invisible.id)
  end

  def show_preview_objects
    DataObjectsHierarchyEntry.
      joins(:data_object, data_object: :data_objects_harvest_events).
      where(visibility_id: Visibility.get_preview.id,
        data_objects_harvest_events: { harvest_event_id: id }).
      update_all(["visibility_id = ?", Visibility.get_visible.id])
  end

  def sync_collection
    HarvestEvent::CollectionManager.sync(self)
  end

  def taxon_concept_ids
    HarvestEventsHierarchyEntry.
      select("DISTINCT hierarchy_entries.taxon_concept_id").
      joins(:hierarchy_entry).
      where(harvest_event_id: id).
      pluck("hierarchy_entries.taxon_concept_id")
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

  private

  # TODO: I don't know if this is the right thing to do; the "overlap" here may
  # or may not work depending on whether the harvest event has a list of ALL
  # entry ids from the harvest, or only the new entry ids from the harvest. The
  # "Right Thing To Do" is to actually store a list of all entry ids affected by
  # the harvest (which you would have to do during the harvest). We can't affect
  # that yet, sooo...
  def new_hierarchy_entry_ids
    # TODO: ensure we're calling the right methodf here.
    if previous = resource.latest_harvest_event_uncached
      these_leaf_node_ids = Set.new(hierarchy_entries.pluck(:id))
      # We are not currently listing ancestor entries in
      # harvest_events_hierarchy_entries (though perhaps we should). ...So this
      # query looks for the last entry_id from the last harvest, and grabs all
      # ids that are higher than that from THIS harvest.
      ancestor_ids = Set.new(HierarchyEntry.
        where(hierarchy_id: hierarchy.id).
        where(["id > ?", previous.hierarchy_entries.max(:id)]).
        pluck(:id))
      ancestor_ids + these_leaf_node_ids
    else
      hierarchy_entries_with_ancestors.pluck(:id)
    end
  end

  # NOTE: this assumes flattened_ancestors has been constructed! TODO: this
  # seems absurd, in a way... this method implies that only child hierarchy
  # entries are associated with the harvest, which doesn't seem right. ...but,
  # hey: it was coded this way, so perhaps it's the case that harvested entries
  # don't necessarily have their parents harvested at the same time. (?)  NOTE:
  # This will "run" all the queries even if it never finds any published
  # ancestors. I figured this is fine—it doesn't affect anything and it keeps
  # logs consistent. TODO: this does NOT do synonyms, which is weird, since it
  # does synonyms for the harvested entries. Find out if that's correct.
  def publish_and_show_hierarchy_entry_parents
    EOL.log_call
    # TODO: this is "wrong"—the PHP had another way of getting these that didn't use the denormalized DB. Use #hierachy_entries_with_ancestors
    # NOTE: this is a little weird, but it's actually more efficient than the
    # previous PHP algorithm (which walked up the ancestry!). It involves two
    # plucks, which could be done inline, but I'm separating for clarity:
    harvested = hierarchy_entries.published.pluck(:id)
    EOL.log("Found #{harvested.count} published harvested entries", prefix: '.')
    ancestors = HierarchyEntriesFlattened.
      where(hierarchy_entry_id: harvested).pluck("DISTINCT ancestor_id")
    EOL.log("Found #{ancestors.count} ancestors", prefix: '.')
    count = HierarchyEntry.where(id: ancestors, published: false).
      update_all(published: true)
    EOL.log("Published #{count} ancestor entries", prefix: '.')
    count = HierarchyEntry.not_visible.where(id: ancestors).
      update_all(visibility_id: Visibility.get_visible.id)
    EOL.log("Showed #{count} ancestor entries", prefix: '.')
    count = TaxonConcept.unpublished.joins(:hierarchy_entries).
      where(hierarchy_entries: { id: ancestors}).
      update_all("taxon_concepts.published = true")
    EOL.log("Published #{count} ancestor taxa", prefix: '.')
  end
end
