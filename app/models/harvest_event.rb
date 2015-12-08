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

  def content_partner
    resource.content_partner
  end

  # TODO: THIS IS HORRIBLE! AUGH! NOTE: it is only called from
  # FeedController#partner_curation, which is also horrible. We might not need
  # this anymore... if we do, it should probably be re-written _entirely_. :\
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

  def data_object_ids
    data_objects_harvest_events.pluck(:data_object_id)
  end

  # This does not change (and the query is complex), so we cache it:
  def previous_published_harvest
    @previous_published_harvest ||=
      HarvestEvent.published.merge(previous_harvests).last
  end

  def previous_harvest
    previous_harvests.last
  end

  def previous_harvests
    HarvestEvent.where(resource_id: resource_id).where(["id < ?", id])
  end

  # NOTE: this assumes flattened_ancestors has been updated for this Hierarchy!
  def hierarchy_entry_ids_with_ancestors
    return @hierarchy_entry_ids_with_ancestors if
      @hierarchy_entry_ids_with_ancestors
    harvested = hierarchy_entries.pluck(:id)
    ancestors = HierarchyEntriesFlattened.where(hierarchy_entry_id: harvested).
      pluck("DISTINCT ancestor_id")
    @hierarchy_entry_ids_with_ancestors = Set.new(harvested + ancestors).to_a
  end

  def index_for_site_search
    HarvestEvent::SiteSearchIndexer.index(self)
  end

  def index_new_data_objects
    DataObject::Indexer.by_data_object_ids(new_data_object_ids)
  end

  def merge_matching_concepts
    relate_new_hierarchy_entries
    hierarchy.merge_matching_concepts
  end

  def relate_new_hierarchy_entries
    EOL.log_call
    Hierarchy::Relator.relate(hierarchy, entry_ids: new_hierarchy_entry_ids)
  end

  def complete?
    self[:completed_at]
  end

  def latest?
    self[:id] == resource.latest_harvest_event.try(:id)
  end

  def mark_as_published
    update_attributes(published_at: Time.now)
  end

  def published?
    self[:published_at]
  end

  def publish_is_allowed?
    ! published? &&
      complete? &&
      latest?
  end

  def publish_pending?
    ! published? && self.publish?
  end

  def publish_data_objects
    EOL.log_call
    count = data_objects.where(published: false).update_all(published: true)
    EOL.log("(#{count} objects)", prefix: ".")
    count
  end

  # NOTE: You need to call publish_data_objects before this; we don't do it
  # here, because it ends up being inefficient; it's best to do data_objects in
  # a separate transaction, so it needed to be separate.
  def finish_publishing
    publish_and_show_hierarchy_entries
    publish_taxon_concepts
    publish_synonyms
    mark_as_published
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
      where(data_object_id: invisible_ids).
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


  # TODO: The "Right Thing To Do" is to actually store a list of all entry ids
  # affected by the harvest (which you would have to do during the harvest). We
  # can't affect that yet, sooo...
  def new_hierarchy_entry_ids
    @new_hierarchy_entry_ids ||= if previous_published_harvest
      these_leaf_node_ids = Set.new(hierarchy_entries.pluck(:id))
      # We are not currently listing ancestor entries in
      # harvest_events_hierarchy_entries (though perhaps we should). ...So this
      # query looks for the last entry_id from the last harvest, and grabs all
      # ids that are higher than that from THIS harvest.
      new_ancestor_ids = Set.new(HierarchyEntry.
        where(hierarchy_id: hierarchy.id).
        where(["id > ?",
          previous_published_harvest.hierarchy_entries.max(:id)]).
        pluck(:id))
      (new_ancestor_ids + these_leaf_node_ids).to_a
    else
      hierarchy_entry_ids_with_ancestors
    end
  end

  # NOTE: this logic IS repeated (there is no really elegant way to avoid this),
  # so if you change this, change the _ids version!
  def new_data_objects
    @new_data_objects ||= if @new_data_object_ids
      # We already did the hard work, just grab the full objects:
      DataObject.where(id: @new_data_object_ids)
    elsif previous_published_harvest
      these_datos = Set.new(data_objects)
      old_datos = Set.new(previous_published_harvest.data_objects)
      ((old_datos - these_datos) +
        data_objects_of_modified_entries).to_a
    else
      data_objects
    end
  end
  # NOTE: this logic IS repeated (there is no really elegant way to avoid this),
  # so if you change this, change the _objects version!
  def new_data_object_ids
    @new_data_object_ids ||= if previous_published_harvest
      these_dato_ids = Set.new(data_object_ids)
      old_dato_ids = Set.new(previous_published_harvest.data_object_ids)
      ((old_dato_ids - these_dato_ids) +
        data_object_ids_of_modified_entries).to_a
    else
      data_object_ids
    end
  end

  def data_object_ids_of_modified_entries
    data_objects_of_modified_entries.pluck(:data_object_id)
  end

  # NOTE: I _assume_ this is necessary because we've not stored
  # DataObjectsHierarchyEntries for ancestors. If that's the case, then, TODO:
  # we should do that while harvesting. :|
  def data_objects_of_modified_entries
    DataObjectsHierarchyEntry.
      where(hierarchy_entry_id: new_hierarchy_entry_ids)
  end

  def insert_dotocs
    data_objects.select("id").find_in_batches(batch_size: 10_000) do |batch|
      DataObjectsTableOfContent.rebuild_by_ids(batch.map(&:id))
    end
  end

private

  def publish_and_show_hierarchy_entries
    EOL.log_call
    count = HierarchyEntry.where(id: hierarchy_entry_ids_with_ancestors,
      published: false).update_all(published: true)
    EOL.log("Published #{count} entries", prefix: '.')
    count = HierarchyEntry.not_visible.
      where(id: hierarchy_entry_ids_with_ancestors).
      update_all(visibility_id: Visibility.get_visible.id)
    EOL.log("Showed #{count} entries", prefix: '.')
  end

  def publish_taxon_concepts
    count = TaxonConcept.unpublished.joins(:hierarchy_entries).
      where(hierarchy_entries: { id: hierarchy_entry_ids_with_ancestors}).
      update_all("taxon_concepts.published = true")
    EOL.log("Published #{count} taxa", prefix: '.')
  end

  def publish_synonyms
    count = Synonym.unpublished.joins(:hierarchy_entry).
      where(hierarchy_entries: { id: hierarchy_entry_ids_with_ancestors}).
      update_all("synonyms.published = true")
    EOL.log("Published #{count} synonyms", prefix: '.')
  end
end
