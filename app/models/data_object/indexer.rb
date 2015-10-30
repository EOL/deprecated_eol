class DataObject
  class Indexer
    ASSOCIATION_TYPES = ["entry", "che", "user"]
    VETTED_PREFIX = {
      Vetted.trusted.id => 'trusted',
      Vetted.unknown.id => 'unreviewed',
      Vetted.untrusted.id => 'untrusted',
      Vetted.inappropriate.id => 'inappropriate'
    }
    VISIBILITY_PREFIX = {
      Visibility.invisible.id => 'invisible',
      Visibility.visible.id => 'visible',
      Visibility.preview.id => 'preview'
    }

    def self.by_data_object_ids(data_object_ids)
      indexer = self.new
      indexer.by_data_object_ids(data_object_ids)
    end

    def initialize
      @solr = SolrCore::DataObjects.new
    end

    def by_data_object_ids(data_object_ids)
      EOL.log_call
      data_object_ids.in_groups_of(10000, false) do |batch|
        index_batch(batch)
      end
    end

    private

    def index_batch(data_object_ids)
      EOL.log_call
      @objects = {} # TODO: poor variable management, fix
      get_objects(data_object_ids)
      ids = @objects.keys # TODO: lame
      add_ancestries_from_result(get_ancestries(ids))
      add_ancestries_from_result(get_curated_ancestries(ids))
      add_ancestries_from_result(get_user_added_ancestries(ids))
      add_attribute(query: get_ignores(ids), attribute: :ignored_by_user_id,
        value_field: :user_id, array: true)
      add_attribute(query: get_curation(ids), attribute: :curated_by_user_id,
        value_field: :user_id, array: true, dato_id_field: :target_id)
      add_attribute(query: get_resources(ids), attribute: :resource_id,
        value_field: :resource_id)
      add_attribute(query: get_table_of_contents(ids), attribute: :toc_id,
        value_field: :toc_id, array: true)
      add_translations(ids)
      # TODO This is lame.
      @objects.each do |id, attributes|
        @objects[id][:max_vetted_weight] =
          if attributes.has_key?(:trusted_ancestor_id)
          5
        elsif attributes.has_key?(:unreviewed_ancestor_id)
          4
        elsif attributes.has_key?(:untrusted_ancestor_id)
          3
        elsif attributes.has_key?(:inappropriate_ancestor_id)
          2
        else
          1
        end

        @objects[id][:max_visibility_weight] =
          if attributes.has_key?(:visible_ancestor_id)
          4
        elsif attributes.has_key?(:invisible_ancestor_id)
          3
        elsif attributes.has_key?(:preview_ancestor_id)
          2
        else
          1
        end
      end
      last = @objects.keys.first
      # Sorry this is complicated; it's really just pulling out the :instance
      # (which is a data object), calling #to_hash on that (q.v.), then merging
      # it with what's left in the object (which is all that ancilary stuff we
      # just added.)
      @solr.reindex_hashes(objects_to_hashes)
    end

    def get_objects(data_object_ids)
      EOL.log_call
      DataObject.
        # TODO: This was designed to minimize queries... to go to the DB once
        # (per batch) and get back everything needed. I don't see that as very
        # efficient. This could be much clearer code, and not take THAT much
        # longer if it just gathered the IDs it needed and made multiple
        # queries, one for each type of table. The juice is not worth the
        # squeeze, with this design. NOTE: I broke these up on single lines,
        # because there was so much going on here, this was clearer than
        # smooshing them into longer lines. Sorry to take up so much space,
        # though. NOTE: Yes, "entry_entry_id" is redundant; necessary. See
        # below.
        select("data_objects.*, "\
          "he.id entry_entry_id, "\
          "he.taxon_concept_id entry_concept_id, "\
          "dohe.vetted_id entry_vetted_id, "\
          "dohe.visibility_id entry_visibility_id, "\
          "che.id che_entry_id, "\
          "che.taxon_concept_id che_concept_id, "\
          "cudohe.vetted_id che_vetted_id, "\
          "cudohe.visibility_id che_visibility_id, "\
          "udo.taxon_concept_id user_concept_id, "\
          "udo.vetted_id user_vetted_id, "\
          "udo.visibility_id user_visibility_id, "\
          "udo.user_id user_id").
        joins("LEFT JOIN "\
          "  (data_objects_hierarchy_entries dohe "\
          "    JOIN hierarchy_entries he ON (dohe.hierarchy_entry_id=he.id))"\
          "  ON (data_objects.id=dohe.data_object_id) "\
          "LEFT JOIN "\
          "  (curated_data_objects_hierarchy_entries cudohe "\
          "    JOIN hierarchy_entries che "\
          "    ON (cudohe.hierarchy_entry_id=che.id)) "\
          "  ON (data_objects.id=cudohe.data_object_id) "\
          "LEFT JOIN users_data_objects udo "\
          "  ON (data_objects.id=udo.data_object_id)").
        where(["data_objects.published = 1 OR dohe.visibility_id = ? AND "\
          "data_objects.id IN (?)", Visibility.preview.id, data_object_ids]).
        find_each do |dato|
        # Because of LEFT JOINs (sigh), we could have the same data object
        # more than once, sooo:
        unless @objects.has_key?(dato.id)
          dato.data_subtype_id ||= 0
          dato.language_id ||= 0
          dato.license_id ||= 0
          @objects[dato.id] = { instance: dato }
        end
        ASSOCIATION_TYPES.each do |type|
          if dato["#{type}_taxon_concept_id"]
            add_association(type, dato)
          end
        end
      end
    end

    def add_association(type, dato)
      concept_id = dato["#{type}_concept_id"]
      @objects[dato.id][:taxon_concept_id] ||= []
      @objects[dato.id][:taxon_concept_id] << concept_id
      if entry_id = dato["#{type}_entry_id"]
        @objects[dato.id][:hierarchy_entry_id] ||= []
        @objects[dato.id][:hierarchy_entry_id] << entry_id
      end
      if dato["user_id"]
        @objects[dato.id][:added_by_user_id] = dato["user_id"]
      end
      [
        VETTED_PREFIX[dato["#{type}_vetted_id"]],
        VISIBILITY_PREFIX[dato["#{type}_visibility_id"]]
      ].compact.
        each do |prefix|
        @objects[dato.id]["#{prefix}_taxon_concept_id".to_sym] ||= []
        @objects[dato.id]["#{prefix}_taxon_concept_id".to_sym] << entry_id
      end
    end

    def get_ancestries(data_object_ids)
      DataObject.
        select("data_objects.id, hierarchy_entries.taxon_concept_id, "\
          "data_objects_hierarchy_entries.vetted_id, "\
          "data_objects_hierarchy_entries.visibility_id, tcf.ancestor_id").
        joins(:hierarchy_entries).
        joins("LEFT JOIN taxon_concepts_flattened tcf ON "\
          "(hierarchy_entries.taxon_concept_id = tcf.taxon_concept_id)").
        # NOTE: This check on NOT visible strikes me as odd... but the PHP code
        # did it in two places (granted, it could have been copy/pasted in
        # error). But this says "where the object is published, or, if it's not,
        # where the association is NOT visible." That does not seem right. :|
        # TODO: is this a bug? ...That said, I imagine the only reason we would
        # want to index _unpublished_ images is if they are preview.
        where(["(data_objects.published = 1 OR "\
          "data_objects_hierarchy_entries.visibility_id != ?) AND "\
          "data_objects.id IN (?)",
          Visibility.visible.id, data_object_ids])
    end

    def get_curated_ancestries(data_object_ids)
      DataObject.
        select("data_objects.id, hierarchy_entries.taxon_concept_id, "\
          "curated_data_objects_hierarchy_entries.vetted_id, "\
          "curated_data_objects_hierarchy_entries.visibility_id, tcf.ancestor_id").
        joins(curated_data_objects_hierarchy_entries: :hierarchy_entry).
        joins("LEFT JOIN taxon_concepts_flattened tcf ON "\
          "(hierarchy_entries.taxon_concept_id = tcf.taxon_concept_id)").
        # NOTE: see the note on the where clause of #get_ancestries
        where(["(data_objects.published = 1 OR "\
          "curated_data_objects_hierarchy_entries.visibility_id != ?) AND "\
          "data_objects.id IN (?)",
          Visibility.visible.id, data_object_ids])
    end

    # NOTE: For consistency, I'm pulling this from DataObject. It could actually
    # be done pulling right from UsersDataObject. I'm not sure what the
    # performance difference is, but it's probably not zero.
    def get_user_added_ancestries(data_object_ids)
      DataObject.
        select("data_objects.id, users_data_objects.taxon_concept_id, "\
          "users_data_objects.vetted_id, "\
          "users_data_objects.visibility_id, tcf.ancestor_id").
        joins(:users_data_object).
        joins("LEFT JOIN taxon_concepts_flattened tcf ON "\
          "(users_data_objects.taxon_concept_id = tcf.taxon_concept_id)").
        where(["data_objects.id IN (?)", data_object_ids])
    end

    def add_ancestries_from_result(query, field_suffix = :ancestor_id)
      EOL.log_call
      query.find_each do |dato|
        # NOTE: this should not happen, but PHP had it. :\
        next unless @objects.has_key?(dato.id)
        # A modicum of brevity:
        concept_id = dato["taxon_concept_id"]
        ancestor_id = dato["ancestor_id"]
        @objects[dato.id][field_suffix] ||= [] # TODO: set?
        @objects[dato.id][field_suffix] << concept_id if concept_id
        @objects[dato.id][field_suffix] << ancestor_id if ancestor_id
        [ VETTED_PREFIX[dato["vetted_id"]],
          VISIBILITY_PREFIX[dato["visibility_id"]] ].compact.
          each do |prefix|
          @objects[dato.id]["#{prefix}_#{field_suffix}".to_sym] ||= []
          @objects[dato.id]["#{prefix}_#{field_suffix}".to_sym] <<
            concept_id if concept_id
          @objects[dato.id]["#{prefix}_#{field_suffix}".to_sym] <<
            ancestor_id if ancestor_id
        end
      end
    end

    # Gott im Himmel, I wish the data objects table just had the dern
    # resource_id in it.
    def get_resources(data_object_ids)
      DataObjectsHarvestEvent.
        select("data_object_id, resource_id").
        joins(:harvest_event).
        where(["data_object_id IN (?) AND harvest_event_id IN (?)",
          data_object_ids, HarvestEvent.latest_ids])
    end

    # Curators who ignore data objects from the worklist tab:
    def get_ignores(data_object_ids)
      WorklistIgnoredDataObject.
        where(["data_object_id IN (?)", data_object_ids])
    end

    # TODO: do we really use this?  :S  It's in the wrong place, even if we do.
    # ...and, of course, ChangeableObjectType is the worst thing ever.
    def get_curation(data_object_ids)
      CuratorActivityLog.
        select("target_id, user_id").
        joins("JOIN translated_activities ta").
        where(["ta.name IN ('trusted', 'untrusted', 'hide', 'show', "\
          "'inappropriate', 'unreviewed', 'add_association', "\
          "'add_common_name') AND changeable_object_type_id IN (?) AND "\
          "target_id IN (?)",
          [ChangeableObjectType.data_object.id,
            ChangeableObjectType.data_objects_hierarchy_entry.id],
          data_object_ids])
    end

    # TODO: do we actually use this? I'm not sure we do. :\
    def get_table_of_contents(data_object_ids)
      DataObjectsTableOfContent.
        select("data_object_id, toc_id").
        where(["data_object_id IN (?)", data_object_ids])
    end

    def add_attribute(options = {})
      EOL.log_call
      options[:query].find_each do |item|
        id = item.send(options[:dato_id_field] || :data_object_id)
        next unless @objects.has_key?(id)
        if options[:array]
          @objects[id][options[:attribute]] ||= []
          @objects[id][options[:attribute]] << item[options[:value_field].to_s]
        else
          @objects[id][options[:attribute]] = item[options[:value_field].to_s]
        end
      end
    end

    def add_translations(data_object_ids)
      EOL.log_call
      DataObjectTranslation.
        select("data_object_id, original_data_object_id").
        where(["data_object_id IN (?)", data_object_ids]).
        find_each do |dot|
        next unless @objects.has_key?(dot.data_object_id)
        @objects[dot.data_object_id][:is_translation] = 1
      end
    end

    def objects_to_hashes
      EOL.log_call
      # TODO: don't cache this; if we change something, we want it recalculated.
      @hashes ||= @objects.values.map do |object|
        object.delete(:instance).
        to_hash.merge(object)
      end
    end
  end
end
