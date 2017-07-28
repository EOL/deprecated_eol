module Export
  class CollectionsAndRelated
    def self.save
      start_time = Time.now
      resource_collection_ids = Resource.pluck(:collection_id).uniq
      resource_collection_ids += Resource.pluck(:preview_collection_id).uniq
      # There were just under 10,000 collections when I last checked.
      collections = []
      collected_pages = []
      collected_media = []
      collection_associations = []
      Collection.where(published: true, special_collection_id: nil).
        where(["id NOT IN (?)", resource_collection_ids.compact]).
        find_each do |collection|
          c_pages = CollectionItem.where(collection_id: collection.id,
            collected_item_type: "TaxonConcept")
          media = CollectionItem.where(collection_id: collection.id,
            collected_item_type: "DataObject")
          col_associations = CollectionItem.where(collection_id: collection.id,
            collected_item_type: "Collection")
          page_ids = c_pages.pluck(:collected_item_id).uniq.compact
          # Now we have to add pages where the media need them:
          media_pages = {}
          media_annotations = {}
          media.each do |medium|
            # This will be slow. I don't care. Not enough to worry.
            tid = medium.collected_item.try(:associations).try(:first).
              try(:taxon_concept_id)
            media_pages[tid] ||= []
            media_pages[tid] << medium.id
            media_annotations[tid] ||= []
            media_annotations[tid] << medium.annotation
          end
          page_ids += media_pages.keys
          page_ids.uniq!
          collections << {
            id: collection.id,
            name: collection.name,
            description: collection.description,
            # We're going to lose our icons, and I think that's okay...
            created_at: collection.created_at,
            updated_at: collection.updated_at
            # We're going to lose the default_sort too... and, again: NBD.
          }
          page_map = {}
          c_pages.each do |c_page|
            page_map[c_page.collected_item_id] = c_page
          end
          page_ids.each do |page_id|
            created_at = page_map[page_id].try(:created_at) || Time.now
            updated_at = page_map[page_id].try(:updated_at) || Time.now
            annotation = page_map[page_id].try(:annotation)
            annotation ||= ""
            annotation += media_annotations[page_id].join("; ")
            collected_pages << {
              collection_id: collection.id,
              page_id: page_id,
              # Argh, we lose the position. :|
              created_at: created_at,
              updated_at: updated_at,
              annotation: annotation
            }
          end
          media_pages.each do |taxon_id, medium_ids|
            medium_ids.each do |medium_id|
              collected_media << {
                collected_page_id: taxon_id,
                medium_id: medium_id
                # Again, we lose position...
              }
            end
          end
          col_associations.each do |assoc|
            collection_associations << {
              collection_id: collection.id,
              # No position...
              created_at: assoc.created_at,
              updated_at: assoc.updated_at,
              associated_id: assoc.collected_item_id,
              annotation: assoc.annotation
            }
          end
          last if collections > 10 # TESTING
        end
      # Note that the above was "normally" extra-nested because of a multi-line query.
      name = Rails.root.join("public", "collections.json").to_s
      File.unlink(name) if File.exist?(name)
      summary = "Exporting Collections: #{@collections.size}, "\
        "collected_pages: #{@collected_pages.size}, "\
        "collected_media: #{@collected_media.size}, "\
        "collection_associations: #{@collection_associations.size} "
      puts summary
      EOL.log(summary, prefix: ".")
      data = {
        collections: collections,
        collected_pages: collected_pages,
        collected_media: collected_media,
        collection_associations: collection_associations
      }
      contents = JSON.pretty_generate(data)
      File.open(name, "w") do |f|
        f.puts(contents)
      end
      File.chmod(0644, name)
      puts "\nDone. Took #{((Time.now - start_time) / 1.minute).round} minutes."
    end
  end
end
