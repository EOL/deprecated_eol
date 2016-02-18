# Rebuilds the (denormalized) tables for TopImage **and** TopUnpublishedImage
# (make NOTE of that!).
class TopImage
  class Rebuilder
    def self.rebuild
      builder = self.new
      builder.rebuild
    end

    def initialize
      @image_data_objects = {}
      @baseline_concept_images = {}
      @baseline_hierarchy_entry_ids = {}
      @top_images = {}
      @top_unpublished_images = {}
    end

    def rebuild
      MediaAssociation.rebuild
      published = Set.new
      unpublished = Set.new
      fields = [:hierarchy_entry_id, :data_object_id, :view_order]
      # This pluck could be huge... many millions of results:
      MediaAssociation.pluck(:hierarchy_entry_id).
        in_groups_of(6400, false) do |ids|
        MediaAssociation.select("hierarchy_entry_id, data_object_id").
          where(hierarchy_entry_id: ids, published: true, visible: true).
          order("hierarchy_entry_id, vet_sort ASC, rating DESC, "\
            "data_object_id ASC").
          group_by { |ma| ma.hierarchy_entry_id }.each do |he_id, assocs|
          assocs.each_with_index do |assoc, pos|
            published << "#{assoc.hierarchy_entry_id},#{assoc.data_object_id},"\
              "#{pos}"
          end
        end
        # Again, but slightly different (unpublished):
        MediaAssociation.select("hierarchy_entry_id, data_object_id").
          where(hierarchy_entry_id: ids).
          where(["published = ? OR visible = ?", false, false]).
          order("vet_sort ASC, rating DESC, data_object_id ASC").
          group_by { |ma| ma.hierarchy_entry_id }.each do |he_id, assocs|
          assocs.each_with_index do |assoc, pos|
            unpublished << "#{assoc.hierarchy_entry_id},"\
              "#{assoc.data_object_id},#{pos}"
          end
        end
      end
      # TopImages isn't really used in production (it's just used to build
      # Solr), so this is safe:
      EOL::Db.truncate_table(TopImage.connection, :top_images)
      EOL::Db.bulk_insert(TopImage, fields, published)
      EOL::Db.truncate_table(TopUnpublishedImage.connection,
        :top_unpublished_images)
      EOL::Db.bulk_insert(TopUnpublishedImage, fields, unpublished)
      # I didn't optimize this stuff, but it seems minimal as-is:
      build_species_table_from("top_images", "top_species_images")
      build_species_table_from("top_unpublished_images",
        "top_unpublished_species_images")
    end

    # NOTE - this is probably not a good idea. NOTE - this actually also handles
    # top_unpublished_images. TODO - instead, we should probably handle these
    # during harvests, replacing candidates as required. More thoughts in the
    # comment where this method is invoked in Manager.
    def old_rebuild
      EOL.log_call
      # TODO - more logging
      get_image_data_objects
      build_baseline_concept_images
      build_baseline_hierarchy_entries
      build_sortable_hashes
      TopImage.connection.transaction do
        EOL::Db.with_tmp_tables([TopImage, TopUnpublishedImage]) do
          bulk_insert_tmp_images(@top_images, @top_unpublished_images)
          bulk_insert_clade_cascades
          EOL::Db.swap_tmp_table(TopImage)
          EOL::Db.swap_tmp_table(TopUnpublishedImage)
          build_species_table_from("top_images", "top_species_images")
          build_species_table_from("top_unpublished_images",
            "top_unpublished_species_images")
        end
      end
    end

    def get_image_data_objects
      EOL.log_call
      DataObjectsTaxonConcept.
        select(data_objects_taxon_concepts: :data_object_id,
          data_objects: :data_rating,
          data_objects_hierarchy_entries: "visibility_id, vetted_id").
        includes(data_object: { data_objects_hierarchy_entries:
          [ :vetted, :visibility ] }).
        where(["data_objects.data_type_id = ? AND "\
          "(data_objects.published = 1 OR "\
          "data_objects_hierarchy_entries.visibility_id = ?)",
          DataType.image.id, Visibility.get_visible.id]).
        find_each do |dot|
        # NOTE - this array could get quite large (millions of entries)
        @image_data_objects[dot.data_object_id] = {
          data_rating: dot.data_object.data_rating,
          visibility_id: dot.data_object.data_objects_hierarchy_entries.
            map(&:visibility_id),
          vetted_view_order: dot.data_object.data_objects_hierarchy_entries.
            map { |dohe| dohe.vetted.sort_weight },
        }
      end
    end

    def build_baseline_concept_images
      EOL.log_call
      @image_data_objects.keys.in_groups_of(10000, false) do |batch|
        DataObjectsTaxonConcept.select("taxon_concept_id, data_object_id").
          where(data_object_id: batch).each do |dot|
            @baseline_concept_images[dot.taxon_concept_id] ||= []
            @baseline_concept_images[dot.taxon_concept_id] << dot.data_object_id
          end
      end
    end

    def build_baseline_hierarchy_entries
      EOL.log_call
      @baseline_concept_images.keys.in_groups_of(10000, false) do |batch|
        HierarchyEntry.use_index("concept_published_visible").
          select("taxon_concept_id, id").
          where(taxon_concept_id: batch).
          where(["((published = 1 AND visibility_id = ?) OR "\
            "(published = 0 AND visibility_id = ?))",
            Visibility.get_visible.id, Visibility.get_preview.id]).each do |he|
          @baseline_hierarchy_entry_ids[he.taxon_concept_id] ||= []
          @baseline_hierarchy_entry_ids[he.taxon_concept_id] << he.id
        end
      end
    end

    # TODO - This is silly. Just store (simple) hashes, use a sort_by on those.
    # He chose this method to sort the results, though, and I am porting it
    # straight from that for now.
    def build_sortable_hashes
      EOL.log_call
      @baseline_concept_images.each do |tc_id, datos|
        next unless @baseline_hierarchy_entry_ids[tc_id]
        datos.each do |dato_id, val|
          next unless @image_data_objects[dato_id]
          data_rating = @image_data_objects[dato_id][:data_rating]
          visibility_id = @image_data_objects[dato_id][:visibility_id]
          vetted_view_order = @image_data_objects[dato_id][:vetted_view_order]
          is_preview = visibility_id == Visibility.get_preview.id
          @baseline_hierarchy_entry_ids.each do |key, hierarchy_entry_ids|
            hierarchy_entry_ids.each do |hierarchy_entry_id|
              which = nil # scope
              if is_preview
                which = @top_unpublished_images
              else
                which = @top_images
              end
              which[hierarchy_entry_id] ||= {}
              which[hierarchy_entry_id][vetted_view_order] ||= {}
              which[hierarchy_entry_id][vetted_view_order][data_rating] ||= {}
              which[hierarchy_entry_id][vetted_view_order][data_rating][dato_id] =
                "#{hierarchy_entry_id}, #{dato_id}"
            end
          end
        end
      end
    end

    def build_species_table_from(source, target)
      EOL.log_call
      EOL::Db.truncate_table(TopImage.connection, target)
      TopImage.connection.execute("INSERT INTO #{target} "\
        "(SELECT ti.* FROM hierarchy_entries he "\
        "JOIN #{source} ti ON (he.id = ti.hierarchy_entry_id) "\
        "WHERE he.rank_id IN (#{Rank.species_rank_ids.join(',')}) OR "\
        "he.lft = he.rgt - 1)")
    end

    def bulk_insert_tmp_images(top_images, top_unpublished_images, options = {})
      EOL.log_call
      options.merge!(tmp: true)
      EOL::Db.bulk_insert(TopImage,
        [:hierarchy_entry_id, :data_object_id],
        crazy_hash_sort(top_images),
        options)
      EOL::Db.bulk_insert(TopUnpublishedImage,
        [:hierarchy_entry_id, :data_object_id],
        crazy_hash_sort(top_unpublished_images),
        options)
    end

    # Find all of the parents (all the way up), and calculate the "best" images
    # for each, then insert those.
    def bulk_insert_clade_cascades
      EOL.log_call
      # Parents of all the visible leaf nodes with images:
      all_parent_ids = Set.new
      parent_ids = Set.new
      HierarchyEntry.select("id, parent_id").
        joins("JOIN top_images_tmp ti "\
          "ON (hierarchy_entries.id = ti.hierarchy_entry_id)").
        where("parent_id != 0").find_each do |he|
        parent_ids << he.parent_id
      end
      more_parents = find_best_images_in_clade(parent_ids)
      until(more_parents.blank?)
        all_parent_ids += more_parents
        more_parents = find_best_images_in_clade(parent_ids)
      end
    end

    # hash[hierarchy_entry_id][vetted_view_order][data_rating][dato_id] =
    #   "#{hierarchy_entry_id}, #{dato_id}"
    def crazy_hash_sort(hash)
      EOL.log_call
      results = []
      hash.keys.sort.each do |hierarchy_entry_id|
        view_order = 1
        top_entry_images = hash[hierarchy_entry_id]
        top_entry_images.keys.sort.each do |vetted_orders|
          ratings = top_entry_images[vetted_orders]
          ratings.keys.sort.reverse.each do |r|
            object_ids = ratings[r]
            object_ids.keys.sort.reverse.each do |object_id|
              results << object_ids[object_id]
              last if view_order > IMAGE_LIMIT
            end
            last if view_order > IMAGE_LIMIT
          end
          last if view_order > IMAGE_LIMIT
        end
      end
      EOL.log_return
      results
    end

    # TODO - long method, break up
    def find_best_images_in_clade(parent_ids)
      EOL.log_call
      next_level_of_parents = Set.new
      parent_ids.to_a.in_groups_of(5000, false) do |group|
        # Ooof. This is complex and I don't want to re-write the entire
        # algorithm to avoid it. Basically what it's doing is grabbing the top
        # images for these IDs, and then all of the top images for all of the
        # children of those ids (so it can find the "best" ones in the clade).
        # I don't believe this is an efficient way of doing this, but because
        # it isn't a priority, I'm going to leave it as-is:
        results = HierarchyEntry.connection.select_all(
          "(SELECT he.id hierarchy_entry_id, he.parent_id, do.id data_object_id,
            do.data_rating, dohe.visibility_id, dohe.vetted_id, do.published
              FROM hierarchy_entries he
              JOIN top_images_tmp ti ON (he.id=ti.hierarchy_entry_id)
              JOIN data_objects do ON (ti.data_object_id=do.id)
              JOIN data_objects_hierarchy_entries dohe
                ON (do.id=dohe.data_object_id)
              WHERE he.id IN (#{parent_ids.to_a.join(',')}))
          UNION
          (SELECT he.id hierarchy_entry_id, he.parent_id, do.id data_object_id,
            do.data_rating, dohe.visibility_id, dohe.vetted_id, do.published
              FROM hierarchy_entries he
              JOIN hierarchy_entries he_children
                ON (he.id=he_children.parent_id)
              JOIN top_images_tmp ti ON (he_children.id=ti.hierarchy_entry_id)
              JOIN data_objects do ON (ti.data_object_id=do.id)
              JOIN data_objects_hierarchy_entries dohe
                ON (do.id=dohe.data_object_id)
              WHERE he.id IN (#{parent_ids.to_a.join(',')}))
          ORDER BY hierarchy_entry_id"
        )
        # TODO - Method here
        # I'm just going to say this one more time: this is too complex and silly.
        # But I am in too much of a rush to re-engineer. :|
        current_entry_id = 0
        top_images = {}
        top_unpublished_images = {}
        he_ids = []
        used_data_objects = []
        # We are going to use this a bajillion times, cache it:
        vet_weights = Hash[*(Vetted.all.flat_map { |v| [v.id, v.sort_weight] })]
        results.each do |row|
          next_level_of_parents << row["parent_id"]
          if row["hierarchy_entry_id"] != current_entry_id &&
            ! top_images.keys.nil?
            # this is a new entry so commit existing data before adding more
            bulk_insert_tmp_images(top_images, top_unpublished_images,
              ignore: true)
            he_ids << current_entry_id
            current_entry_id = row["hierarchy_entry_id"]
            top_images = {}
            top_unpublished_images = {}
            used_data_objects = []
          end
          next if used_data_objects.include?(row["data_object_id"])
          used_data_objects << row["data_object_id"]
          vetted_sort_order = vet_weights[row["vetted_id"]] || 5
          which = nil
          if row["visibility_id"] == Visibility.get_visible.id &&
            row["published"] == 1
            which = top_images
          else
            which = top_unpublished_images
          end
          # Again with the crazy hash:
          which[row["hierarchy_entry_id"]] ||= {}
          which[row["hierarchy_entry_id"]][vetted_sort_order] ||= {}
          which[row["hierarchy_entry_id"]][vetted_sort_order][row["data_rating"]] ||= {}
          which[row["hierarchy_entry_id"]][vetted_sort_order][row["data_rating"]][row["data_object_id"]] =
            "#{row["hierarchy_entry_id"]}, #{row["data_object_id"]}"
        end
        # Once again, now that we're done with results:
        bulk_insert_tmp_images(top_images, top_unpublished_images, ignore: true)
        unless top_images.keys.empty? && top_unpublished_images.keys.empty?
          # We didn't end cleanly:
          he_ids << current_entry_id
        end
        # NOTE - Honestly, I am not sure why we do these deletes, but it was there
        # and I trust it was important. :|
        he_ids.in_groups_of(5000, false) do |group|
          TopImage.connection.execute(
            "DELETE FROM top_images_tmp WHERE hierarchy_entry_id IN "\
              "(#{group.join(',')})")
        end
        next_level_of_parents.delete(nil) # Just in case.
        next_level_of_parents
      end
    end
  end
end
