module EOL
  module Solr
    class CollectionItemsCoreRebuilder

      attr_accessor :solr_api, :objects_to_send_to_solr, :debug

      def self.begin_rebuild
        rebuilder = EOL::Solr::CollectionItemsCoreRebuilder.new
        rebuilder.index_all_collection_items
      end

      def self.reindex_collection(collection)
        EOL.log("reindexing collection #{collection.id}", prefix: "#")
        rebuilder = EOL::Solr::CollectionItemsCoreRebuilder.new
        rebuilder.index_collection(collection.id)
        EOL.log("Counting items...", prefix: ".")
        # update collection items count
        collection.update_attributes(collection_items_count: collection.collection_items.count)
      end

      def self.reindex_collection_items(collection_items)
        rebuilder = EOL::Solr::CollectionItemsCoreRebuilder.new
        rebuilder.index_collection_items_by_id(collection_items.map(&:id))
      end

      def self.reindex_collection_items_by_ids(collection_item_ids)
        return unless collection_item_ids && collection_item_ids.class == Array
        rebuilder = EOL::Solr::CollectionItemsCoreRebuilder.new
        rebuilder.index_collection_items_by_id(collection_item_ids)
      end

      def self.remove_collection(collection)
        rebuilder = EOL::Solr::CollectionItemsCoreRebuilder.new
        rebuilder.remove_collection_by_id(collection.id)
      end

      def self.remove_collection_items(items)
        rebuilder = EOL::Solr::CollectionItemsCoreRebuilder.new
        rebuilder.solr_api.delete_by_ids(items.map(&:id))
      end

      def initialize(options={})
        @solr_api = SolrAPI.new($SOLR_SERVER, $SOLR_COLLECTION_ITEMS_CORE)
        @objects_to_send_to_solr = []
        @debug = options[:debug]
      end

      def index_collection(collection_id)
        return unless collection_id && collection_id.class == Fixnum
        remove_collection_by_id(collection_id)
        result = Collection.connection.execute("SELECT id FROM collection_items WHERE collection_id = #{collection_id}")
        index_collection_items_by_id(result.collect{ |r| r.first })
      end

      def remove_collection_by_id(collection_id)
        solr_api.delete_by_query("collection_id:#{collection_id}")
      end

      def index_all_collection_items
        solr_api.delete_all_documents
        batch_size = 100000
        start = CollectionItem.first.id rescue 0
        max_id = CollectionItem.last.id rescue 0
        start_time = Time.now
        while start <= max_id
          puts "Processing ids #{start} to #{start + batch_size - 1} of #{max_id}. Running time #{Time.now - start_time} seconds" if debug
          result = Collection.connection.execute("SELECT id FROM collection_items WHERE id BETWEEN #{start} AND #{start + batch_size - 1}")
          index_collection_items_by_id(result.collect{ |r| r.first })
          start += batch_size
        end
      end

      def index_collection_items_by_id(collection_item_ids)
        return unless collection_item_ids && collection_item_ids.class == Array
        collection_item_ids.each_slice(10000) do |batch_ids|
          index_batch(batch_ids)
        end
      end

      private

      def index_batch(collection_item_ids)
        return unless collection_item_ids && collection_item_ids.class == Array
        self.objects_to_send_to_solr = []
        lookup_data_objects(collection_item_ids)
        lookup_taxon_concepts(collection_item_ids)
        lookup_users(collection_item_ids)
        lookup_collections(collection_item_ids)
        lookup_communities(collection_item_ids)
        solr_api.delete_by_ids(collection_item_ids, :commit => false)
        unless self.objects_to_send_to_solr.blank?
          solr_api.create(self.objects_to_send_to_solr)
        end
      end

      def lookup_data_objects(collection_item_ids)
        query = "SELECT ci.id, ci.annotation, ci.added_by_user_id, UNIX_TIMESTAMP(ci.created_at), UNIX_TIMESTAMP(ci.updated_at),
          ci.collected_item_id, ci.collection_id, do.object_title, ci.sort_field, NULL, NULL,
          do.data_type_id, do.data_rating, ttoc.label
          FROM collection_items ci
          STRAIGHT_JOIN data_objects do ON (ci.collected_item_id=do.id)
          LEFT JOIN
            (table_of_contents toc JOIN data_objects_table_of_contents dotoc ON (toc.id=dotoc.toc_id)
            JOIN translated_table_of_contents ttoc ON (toc.id=ttoc.table_of_contents_id AND ttoc.language_id=#{Language.english.id}))
            ON (do.id=dotoc.data_object_id)
          WHERE collected_item_type='DataObject'
          AND ci.id IN (#{collection_item_ids.join(',')})"
        collect_data_from_query(query, 'DataObject')
      end

      def lookup_taxon_concepts(collection_item_ids)
        query = "SELECT ci.id, ci.annotation, ci.added_by_user_id, UNIX_TIMESTAMP(ci.created_at), UNIX_TIMESTAMP(ci.updated_at),
          ci.collected_item_id, ci.collection_id, ci.name, ci.sort_field, tcm.richness_score, n.string name_string, NULL, NULL, NULL
          FROM collection_items ci
          LEFT JOIN taxon_concept_metrics tcm ON (ci.collected_item_id=tcm.taxon_concept_id)
          LEFT JOIN
              (taxon_concept_preferred_entries tcpe
                  JOIN hierarchy_entries he ON (tcpe.hierarchy_entry_id=he.id)
                  JOIN names n ON (he.name_id=n.id))
              ON (ci.collected_item_id=tcpe.taxon_concept_id)
          WHERE collected_item_type='TaxonConcept'
          AND ci.id IN (#{collection_item_ids.join(',')})"
        collect_data_from_query(query, 'TaxonConcept')
      end

      def lookup_users(collection_item_ids)
        query = "SELECT ci.id, ci.annotation, ci.added_by_user_id, UNIX_TIMESTAMP(ci.created_at), UNIX_TIMESTAMP(ci.updated_at),
          ci.collected_item_id, ci.collection_id, u.username, ci.sort_field, NULL, NULL, NULL, NULL, NULL
          FROM collection_items ci
          STRAIGHT_JOIN users u ON (ci.collected_item_id=u.id)
          WHERE collected_item_type='User'
          AND ci.id IN (#{collection_item_ids.join(',')})"
        collect_data_from_query(query, 'User')
      end

      def lookup_communities(collection_item_ids)
        query = "SELECT ci.id, ci.annotation, ci.added_by_user_id, UNIX_TIMESTAMP(ci.created_at), UNIX_TIMESTAMP(ci.updated_at),
          ci.collected_item_id, ci.collection_id, c.name, ci.sort_field, NULL, NULL, NULL, NULL, NULL
          FROM collection_items ci
          STRAIGHT_JOIN communities c ON (ci.collected_item_id=c.id)
          WHERE collected_item_type='Community'
          AND ci.id IN (#{collection_item_ids.join(',')})"
        collect_data_from_query(query, 'Community')
      end

      def lookup_collections(collection_item_ids)
        query = "SELECT ci.id, ci.annotation, ci.added_by_user_id, UNIX_TIMESTAMP(ci.created_at), UNIX_TIMESTAMP(ci.updated_at),
          ci.collected_item_id, ci.collection_id, c.name, ci.sort_field, NULL, NULL, NULL, NULL, NULL
          FROM collection_items ci
          STRAIGHT_JOIN collections c ON (ci.collected_item_id=c.id)
          WHERE collected_item_type='Collection'
          AND ci.id IN (#{collection_item_ids.join(',')})"
        collect_data_from_query(query, 'Collection')
      end

      def collect_data_from_query(query, row_type)
        return unless query && row_type
        collection_ids_added = {}
        result = Collection.connection.execute(query)
        result.each do |row|
          collection_item_id = row[0];
          next if collection_ids_added[collection_item_id]
          annotation = row[1]
          added_by_user_id = row[2] || 0
          created_at = row[3] ? Time.at(row[3]).solr_timestamp : '1960-01-01T00:00:01Z'
          updated_at = row[4] ? Time.at(row[4]).solr_timestamp : '1960-01-01T00:00:01Z'
          object_id = row[5]
          collection_id = row[6]
          title = row[7]
          sort_field = row[8]
          # taxon-specific fields
          richness_score = row[9] || 0
          name_string = row[10]
          # object-specific fields
          data_object_data_type_id = row[11]
          data_object_rating = row[12] || 0
          data_object_subject = row[13]
          data_object_title = row[14]
          object_type = row_type.dup

          if object_type == 'TaxonConcept'
            title = name_string unless name_string.blank?
            title = 'zzz' if title.blank?
          end

          if object_type == "DataObject"
            if DataType.text_type_ids.include?(data_object_data_type_id)
              object_type = "Text"
            elsif DataType.image_type_ids.include?(data_object_data_type_id)
              object_type = "Image"
            elsif DataType.sound_type_ids.include?(data_object_data_type_id)
              object_type = "Sound"
            elsif DataType.video_type_ids.include?(data_object_data_type_id)
              object_type = "Video"
            elsif DataType.map_type_ids.include?(data_object_data_type_id)
              object_type = "Map"
            end

            if title.blank?
              if DataType.text_type_ids.include?(data_object_data_type_id) && !data_object_subject.blank?
                title = data_object_subject
              else
                title = object_type
              end
            end
          end

          self.objects_to_send_to_solr << {
            'collection_item_id'  => collection_item_id,
            'object_type'         => object_type,
            'object_id'           => object_id,
            'collection_id'       => collection_id,
            'annotation'          => SolrAPI.text_filter(annotation),
            'added_by_user_id'    => added_by_user_id,
            'date_created'        => created_at,
            'date_modified'       => updated_at,
            'title'               => SolrAPI.text_filter(title),
            'richness_score'      => richness_score,
            'data_rating'         => data_object_rating
          }
          # Don't even add the sort field unless it has something in it; it MUST be *missing* in order to sort last.
          # TODO - try passing nil if it's blank, perhaps that's enough for it to be missing.
          self.objects_to_send_to_solr.last['sort_field'] = SolrAPI.text_filter(sort_field) unless sort_field.blank?
          collection_ids_added[collection_item_id] = true
        end
      end

    end
  end
end
