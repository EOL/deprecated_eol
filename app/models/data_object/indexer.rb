class DataObject
  class Indexer

    def self.by_data_object_ids(data_object_ids)
      indexer = self.new
      indexer.by_data_object_ids(data_object_ids)
    end

    def initialize
      set_prefixes
      @solr = SolrCore::DataObjects.new
      @batch_size = 10_000
    end

    def by_data_object_ids(data_object_ids)
      EOL.log_call
      num = 0
      batch_count = (data_object_ids.size / @batch_size.to_f).ceil
      data_object_ids.in_groups_of(@batch_size, false) do |batch|
        num += 1
        EOL.log("DataObject::Indexer#index_batch #{num}/#{batch_count}",
          prefix: '.')
        index_batch(batch)
      end
      EOL.log_return
    end

    private

    # Because these are indexed by values that aren't in the DB during testing,
    # we should read them when we call the method:
    def set_prefixes
      @vetted_prefix ||= {
        Vetted.trusted.id => 'trusted',
        Vetted.unknown.id => 'unreviewed',
        Vetted.untrusted.id => 'untrusted',
        Vetted.inappropriate.id => 'inappropriate'
      }
      @visibility_prefix ||= {
        Visibility.invisible.id => 'invisible',
        Visibility.visible.id => 'visible',
        Visibility.preview.id => 'preview'
      }
    end

    def index_batch(data_object_ids)
      @objects = {}
      add_native_associations(data_object_ids)
      add_curated_associations(data_object_ids)
      add_user_associations(data_object_ids)
      # Ids that we actually found (some from data_object_ids c/h/b missing)
      ids = @objects.keys
      add_ancestries_from_result(get_partner_association(ids))
      add_ancestries_from_result(get_curated_associations(ids))
      add_ancestries_from_result(get_user_added_associations(ids))
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
      @solr.reindex_hashes(objects_to_hashes)
    end

    def add_native_associations(data_object_ids)
      DataObject.where(id: data_object_ids).
        includes(data_objects_hierarchy_entries: :hierarchy_entry).
        find_each do |dato|
        add_data_object_base(dato)
        dato.data_objects_hierarchy_entries.each do |native_association|
          next unless dato.published? || native_association.preview?
          if taxon_id = native_association.hierarchy_entry.taxon_concept_id
            add_association(dato, native_association,
              type: :entry, taxon_id: taxon_id,
              entry_id: native_association.hierarchy_entry.id)
          end
        end
      end
    end

    def add_curated_associations(data_object_ids)
      DataObject.where(id: data_object_ids).
        includes(curated_data_objects_hierarchy_entries: :hierarchy_entry).
        find_each do |dato|
        dato.curated_data_objects_hierarchy_entries.each do |curated_association|
          next unless dato.published? || curated_association.preview?
          if taxon_id = curated_association.hierarchy_entry.taxon_concept_id
            add_association(dato, curated_association,
              type: :che, taxon_id: taxon_id,
              entry_id: curated_association.hierarchy_entry.id)
          end
        end
      end
    end

    def add_user_associations(data_object_ids)
      DataObject.where(id: data_object_ids).
        includes(:users_data_object).
        find_each do |dato|
        next unless dato.users_data_object
        next unless dato.published? || dato.users_data_object.preview?
        if taxon_id = dato.users_data_object.taxon_concept_id
          add_association(dato, dato.users_data_object, type: :user,
            taxon_id: taxon_id, user_id: dato.users_data_object.user_id)
        end
      end
    end

    def add_data_object_base(dato)
      unless @objects.has_key?(dato.id)
        dato.data_subtype_id ||= 0
        dato.language_id ||= 0
        dato.license_id ||= 0
        @objects[dato.id] = { instance: dato }
      end
    end

    # TODO: (LOW-PRIORITY) it w/b nice to use Sets, here, to avoid duplicates
    # (which we get a lot of). Solr doesn't care, though, so... whatever. For
    # now. NOTE that it's not just a case of turning them into Sets—you must
    # then call #to_a on all of those sets just before dumping them into Solr!
    def add_association(dato, association, options = {})
      taxon_id = options[:taxon_id]
      type = options[:type]
      @objects[dato.id][:taxon_concept_id] ||= []
      @objects[dato.id][:taxon_concept_id] << taxon_id
      if options[:entry_id]
        @objects[dato.id][:hierarchy_entry_id] ||= []
        @objects[dato.id][:hierarchy_entry_id] << options[:entry_id]
      end
      if options["user_id"]
        @objects[dato.id][:added_by_user_id] = options["user_id"]
      end
      [
        @vetted_prefix[association.vetted_id],
        @visibility_prefix[association.visibility_id]
      ].compact.
        each do |prefix|
        @objects[dato.id]["#{prefix}_taxon_concept_id".to_sym] ||= []
        @objects[dato.id]["#{prefix}_taxon_concept_id".to_sym] << taxon_id
      end
    end

    def get_partner_association(data_object_ids)
      DataObject.
        select("data_objects.id, hierarchy_entries.taxon_concept_id, "\
          "data_objects_hierarchy_entries.vetted_id, "\
          "data_objects_hierarchy_entries.visibility_id").
        joins(data_objects_hierarchy_entries: :hierarchy_entry).
        where(["data_objects.published = 1 AND data_objects.id IN (?)",
          data_object_ids])
    end

    def get_curated_associations(data_object_ids)
      DataObject.
        select("data_objects.id, hierarchy_entries.taxon_concept_id, "\
          "curated_data_objects_hierarchy_entries.vetted_id, "\
          "curated_data_objects_hierarchy_entries.visibility_id").
        joins(curated_data_objects_hierarchy_entries: :hierarchy_entry).
        where(["data_objects.published = 1 AND data_objects.id IN (?)",
          data_object_ids])
    end

    # NOTE: For consistency, I'm pulling this from DataObject. It could actually
    # be done pulling right from UsersDataObject. I'm not sure what the
    # performance difference is, but it's probably not zero.
    def get_user_added_associations(data_object_ids)
      DataObject.
        select("data_objects.id, users_data_objects.taxon_concept_id, "\
          "users_data_objects.vetted_id, "\
          "users_data_objects.visibility_id").
        joins(:users_data_object).
        where(["data_objects.id IN (?)", data_object_ids])
    end

    def ancestor_query(concept_id)
      TaxonConcept.where(id: concept_id).
        includes(hierarchy_entries: :flattened_ancestors).
        first.hierarchy_entries.flat_map do |e|
          e.flattened_ancestors.map(&:ancestor_id)
        end.uniq
    end

    # Test:
    if false
      solr = SolrCore::DataObjects.new
      a_ids = solr.paginate("data_object_id:26726692")["response"]["docs"].first["ancestor_id"]
      TaxonConcept.where(id: a_ids).with_title.map(&:title)
      # WRONG set:
      # ["Plantae", "Chromista", "Ochrophyta Cavalier-Smith, 1995", "Phaeophyceae", "Laminariales", "Lessoniaceae", "Khakista", "Bacillariophyceae Haeckel, 1878", "Cymbellales D. G. Mann, 1990", "Lessonia Bory de Saint-Vincent, 1825", "Echinella", "Lessonia", "<i>Gomphonema angusticephalum</i> E.Reichardt & Lange-Bertalot", "<i>Dictyochloropsis irregularis</i>", "<i>Frustulia bisulcata</i> R. Maillard", "<i>Lessonia nigrescens</i>", "Protozoa", "Gomphonemataceae Kützing 1844", "Phaeophyta", "Eukaryota", "Stramenopiles", "Heterokonta", "Biota", "Chromalveolata", "Px clade"]
    end

    def add_ancestries_from_result(query)
      query.find_each do |dato|
        # A modicum of brevity:
        taxon_id = dato["taxon_concept_id"]
        # NOTE this is INEFFICIENT! It's n^2 (kinda). ...But it's a compromise
        # until we get taxon_concepts_flattened working...
        ancestor_ids = ancestor_query(taxon_id)
        @objects[dato.id][:ancestor_id] ||= [] # TODO: set?
        @objects[dato.id][:ancestor_id] << taxon_id if taxon_id
        @objects[dato.id][:ancestor_id] = ancestor_ids unless ancestor_ids.empty?
        [ @vetted_prefix[dato["vetted_id"]],
          @visibility_prefix[dato["visibility_id"]]
        ].compact.
          each do |prefix|
          @objects[dato.id]["#{prefix}_ancestor_id".to_sym] ||= []
          @objects[dato.id]["#{prefix}_ancestor_id".to_sym] <<
            taxon_id if taxon_id
          @objects[dato.id]["#{prefix}_ancestor_id".to_sym] <<
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
    # ...and, of course, ChangeableObjectType is the worst thing ever. TODO: we
    # also should NOT be relying on english translations of activities. Sheesh.
    def get_curation(data_object_ids)
      CuratorActivityLog.
        select("curator_activity_logs.id, target_id, user_id").
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
      @objects.values.map do |object|
        object.delete(:instance).to_hash.merge(object)
      end
    end
  end
end
