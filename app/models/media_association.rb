class MediaAssociation < ActiveRecord::Base
  belongs_to :hierarchy_entry
  belongs_to :data_object

  class << self
    # It's okay to truncate the table here, because it doesn't affect anything in
    # production; we only use this (now) as a kind of temp table to avoid a bunch
    # of work, and eventually rebuild top_images (which itself just goes into a
    # Solr Core and isn't used on the site!)
    def rebuild
      EOL::Db.truncate_table(MediaAssociation.connection, :media_associations)
      fields = [:hierarchy_entry_id, :data_object_id, :rating, :visible, :preview,
        :vet_sort, :published]
      assocs = {}
      merge_associations_from_table(assocs, DataObjectsHierarchyEntry)
      merge_associations_from_table(assocs, CuratedDataObjectsHierarchyEntry)
      data = build_ancestors(assocs)
      EOL::Db.bulk_insert(MediaAssociation, fields, data)
    end

    def merge_associations_from_table(assocs, klass, batch_size = 6400)
      EOL.log_call
      visible = Visibility.get_visible.id
      preview = Visibility.get_preview.id
      weights = Vetted.weight
      offset = 0
      count = 1 # Arbitrary non-zero value
      while count != 0
        EOL.log("offset: #{offset}", prefix: ".")
        query = "SELECT assocs.hierarchy_entry_id he_id, dato.id do_id, "\
          "  dato.data_rating rate, assocs.visibility_id vis, "\
          "  assocs.vetted_id vet, dato.published d_pub, he.published h_pub "\
          "FROM #{klass.table_name} assocs "\
          "  JOIN data_objects dato ON (assocs.data_object_id = dato.id AND "\
          "    dato.data_type_id IN (#{DataType.media_type_ids.join(",")})) "\
          "  JOIN hierarchy_entries he ON (assocs.hierarchy_entry_id = he.id) "
          "LIMIT #{batch_size} OFFSET #{offset}"
        these = klass.connection.select(query)
        count = these.count
        offset += count
        these.each do |this|
          assocs[this["he_id"]] ||= []
          assocs[this["he_id"]] <<
            "#{this["he_id"]},#{this["do_id"]},#{(this["rate"] * 100).to_i},"\
            "#{this["vis"] == visible ? 1 : 0},"\
            "#{this["vis"] == preview ? 1 : 0},"\
            "#{weights[this["vet"]]},"\
            "#{this["d_pub"] == 1 && this["h_pub"] == 1 ? 1 : 0}"
        end
      end
    end

    # NOTE: this assumes ancestors have the same published status as their source.
    # I _think_ that's safe. (In fact, I believe it's forced in publishing.)
    def build_ancestors(assocs)
      data = Set.new(assocs.values.flatten)
      ids = assocs.keys
      ids.in_groups_of(6400, false) do |group|
        FlatEntry.where(hierarchy_entry_id: group).find_each do |flat_entry|
          assocs[flat_entry.hierarchy_entry_id].each do |row|
            data << row.sub(/^\d+/, flat_entry.ancestor_id.to_s)
          end
        end
      end
      data.to_a
    end
  end
end
