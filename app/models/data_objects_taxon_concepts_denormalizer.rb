# Yes, this uses raw SQL. The way things were written, this is unavoidable...
# but in the name of speed, it makes sense here anyway. ...more or less.
class DataObjectsTaxonConceptsDenormalizer
  def self.denormalize
    EOL.log_call
    denormalize_using_joins_via_table({ hierarchy_entries: :data_objects },
      "data_objects_hierarchy_entries")
    denormalize_using_joins_via_table({ hierarchy_entries:
      { curated_data_objects_hierarchy_entries: :data_object } },
      "curated_data_objects_hierarchy_entries")
    denormalize_using_joins_via_table({ users_data_objects: :data_object },
      "users_data_objects")
  end

  def self.denormalize_using_joins_via_table(joins, visibility_table)
    TaxonConcept.unsuperceded.
      select("taxon_concepts.id, data_objects.id as dato_id").
      joins(joins).
      where(["(data_objects.published = 1 OR "\
        "#{visibility_table}.visibility_id != ?)",
        Visibility.get_visible.id ]).
      find_in_batches(batch_size: 50000) do |taxa|
        DataObjectsTaxonConcept.connection.execute(
          "INSERT INTO data_objects_taxon_concepts "\
          "(`taxon_concept_id`, `data_object_id`) "\
          "VALUES (#{taxa.map { |res| "#{res["id"]}, #{res["dato_id"]}" }.
          join("), (")})"
        )
    end
  end
end
