# Used for denormalized searches on (normal, vetted, visible, published) images.
class TopImage < ActiveRecord::Base

  IMAGE_LIMIT = 500 # Limit on how many images to index per TaxonConcept.

  self.primary_keys = :hierarchy_entry_id, :data_object_id
  belongs_to :hierarchy_entry
  belongs_to :data_object

  # NOTE - this is probably not a good idea. NOTE - this actually also does
  # top_unpublished_images. TODO - instead, we should probably handle these
  # during harvests, replacing candidates as required.
  def self.rebuild
    EOL.log_call
    # TODO - more logging
    # TODO - consider running this in one huge transaction, sigh.
    image_data_objects = {}
    baseline_concept_images = {}
    baseline_hierarchy_entry_ids = {}
    # TODO - break up into smaller methods
    DataObjectsTaxonConcept.
      select(data_objects_taxon_concepts: :data_object_id,
        data_objects: data_rating,
        data_objects_hierarchy_entries: [:visibility_id, :vetted_id]).
      includes(data_object: { data_objects_hierarchy_entries:
        [ :vetted, :visibility ] }).
      where(["data_objects.data_type_id = ? AND "\
        "(data_objects.published = 1 OR data_objects_hierarchy_entries = ?)",
        DataType.image.id, Visibility.get_visible.id]).
      find_each do |dot|
      # NOTE - this array could get quite large (millions of entries)
      image_data_objects[dot.data_object_id] = {
        data_rating: dot.data_object.data_rating,
        visibility_id: dot.data_object.data_objects_hierarchy_entries.
          map(&:visibility_id),
        vetted_view_order: dot.data_object.data_objects_hierarchy_entries.
          map { |dohe| dohe.vetted.vetted_weight },
      }
    end
    image_data_objects.keys.in_groups_of(10000, false) do |batch|
      DataObjectsTaxonConcept.select(:taxon_concept_id, :data_object_id).
        where(data_object_id: batch).each do |dot|
          baseline_concept_images[dot.taxon_concept_id] = dot.data_object_id
        end
    end
    baseline_concept_images.keys.in_groups_of(10000, false) do |batch|
      HierarchyEntry.use_index("concept_published_visible").
        select(:taxon_concept_id, :id).
        where(taxon_concept_id: batch).
        where(["((published = 1 AND visibility_id = ?) OR "\
          "(published = 0 AND visibility_id = ?))",
          Visibility.get_visible.id, Visibility.get_preview.id]).each do |he|
        baseline_hierarchy_entry_ids[he.taxon_concept_id] ||= []
        baseline_hierarchy_entry_ids[he.taxon_concept_id] << he.id
      end
    end
    baseline_concept_images.each do |tc_id, datos|
      next unless baseline_hierarchy_entry_ids[tc_id]
      top_images = {}
      top_unpublished_images = {}
      datos.each do |dato_id, val|
        next unless image_data_objects[dato_id]
        data_rating = image_data_objects[dato_id][:data_rating]
        visibility_id = image_data_objects[dato_id][:visibility_id]
        vetted_view_order = image_data_objects[dato_id][:vetted_view_order]
        is_preview = visibility_id == Visibility.get_preview.id
        baseline_hierarchy_entry_ids.each do |key, hierarchy_entry_id|
          # TODO - This is silly. Just store (simple) hashes, use a sort_by on those.
          # He chose this method to sort the results;
          if is_preview
            top_unpublished_images[hierarchy_entry_id] ||= {}
            top_unpublished_images[hierarchy_entry_id][vetted_view_order] ||= {}
            top_unpublished_images[hierarchy_entry_id][vetted_view_order][data_rating] ||= {}
            top_unpublished_images[hierarchy_entry_id][vetted_view_order][data_rating][data_object_id] =
              "#{hierarchy_entry_id}, #{data_object_id}"
          else
            top_images[hierarchy_entry_id] ||= {}
            top_images[hierarchy_entry_id][vetted_view_order] ||= {}
            top_images[hierarchy_entry_id][vetted_view_order][data_rating] ||= {}
            top_images[hierarchy_entry_id][vetted_view_order][data_rating][data_object_id] =
              "#{hierarchy_entry_id}, #{data_object_id}"
          end
        end
      end
    end
    begin
      # TODO - generalize
      connection.execute("DROP TABLE IF EXISTS top_images_tmp")
      connection.execute("DROP TABLE IF EXISTS top_unpublished_images_tmp")
      connection.execute("CREATE TABLE top_images_tmp LIKE top_images")
      connection.execute("CREATE TABLE top_unpublished_images_tmp "\
        "LIKE top_unpublished_images")
      bulk_insert(crazy_hash_sort(top_images), "top_images")
      bulk_insert(crazy_hash_sort(top_unpublished_images),
        "top_unpublished_images")
    ensure
      connection.execute("DROP TABLE IF EXISTS top_images_tmp")
      connection.execute("DROP TABLE IF EXISTS top_unpublished_images_tmp")
    end
    # TODO - YOU WERE HERE
    #     // now start the search of the parents of these concepts
    #     $this->start_process_parents();
    #
    #     // finalize the import, clean up, move temp tables to real tables
    #     $this->end_load_data();
  end

  def self.crazy_hash_sort(hash)
    results = []
    hash.keys.sort.each do |hierarchy_entry_id|
      view_order = 1
      top_entry_images = hash[hierarchy_entry_id]
      top_entry_images.keys.sort.each do |vetted_orders|
        ratings = top_entry_images[vetted_orders]
        ratings.keys.sort.reverse.each do |r|
          object_ids = ratings[r]
          object_ids.keys.sort.reverse.each do |object_id|
            results << "(#{object_ids[object_id]}, #{view_order})"
            last if view_order > IMAGE_LIMIT
          end
          last if view_order > IMAGE_LIMIT
        end
        last if view_order > IMAGE_LIMIT
      end
    end
  end

  # TODO - generalize! Argh. I am sick of doing this over and over...
  def self.bulk_insert(results, table)
    results.in_groups_of(1000) do |group|
      connection.execute("INSERT INTO #{table} "\
        "(hierarchy_entry_id, data_object_id) VALUES #{group.join(', ')}")
    end
  end
end
