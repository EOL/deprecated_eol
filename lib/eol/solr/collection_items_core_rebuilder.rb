module EOL
  module Solr
    class CollectionItemsCoreRebuilder
      attr_reader :solr_api
      attr_reader :objects_to_send

      def initialize()
        @solr_api = SolrAPI.new($SOLR_SERVER, $SOLR_COLLECTION_ITEMS_CORE)
        @objects_to_send = []
      end

      def obliterate
        @solr_api.delete_all_documents
      end

      def begin_rebuild(optimize = true)
        @solr_api.delete_all_documents
        start_to_index_collection_items
        @solr_api.optimize if optimize
      end

      def start_to_index_collection_items
        start = CollectionItem.first.id
        max_id = CollectionItem.last.id
        limit = 5000
        i = start
        while i <= max_id
          @objects_to_send = {}
          lookup_collection_items(i, limit);
          @objects_to_send.each do |k, o|
            o['title'] = SolrAPI.text_filter(o['title'])
            o['annotation'] = SolrAPI.text_filter(o['annotation'])
          end
          @solr_api.send_attributes(@objects_to_send) unless @objects_to_send.blank?
          i += limit
        end
      end

      def lookup_collection_items(start, limit)
        max = start + limit
        collection_items = CollectionItem.find(:all, :conditions => "id BETWEEN #{start} AND #{max}")
        preload_concepts_and_objects!(collection_items)
        collection_items.each do |i|
          begin
            hash = i.solr_index_hash
            hash.delete('collection_item_id')
            @objects_to_send[i.id] = hash
          rescue EOL::Exceptions::InvalidCollectionItemType => e
            puts "** #{e.message}"
          end
        end
      end

      def preload_concepts_and_objects!(collection_items)
        preload_object!(collection_items.select{ |d| d.object_type == 'Community' })
        preload_object!(collection_items.select{ |d| d.object_type == 'Collection' })
        preload_object!(collection_items.select{ |d| d.object_type == 'User' })
        preload_taxon_concepts!(collection_items.select{ |d| d.object_type == 'TaxonConcept' })
        preload_data_objects!(collection_items.select{ |d| ['Image', 'Video', 'Sound', 'Text', 'DataObject'].include?(d.object_type) })
      end

      def preload_object!(collection_items)
        return if collection_items.blank?
        CollectionItem.preload_associations(collection_items, :object)
      end

      def preload_taxon_concepts!(collection_items)
        return if collection_items.blank?
        includes = { :object => [ :taxon_concept_metric,
          { :published_hierarchy_entries => { :name => :canonical_form } } ] }
        selects = {
          :taxon_concepts => 'id',
          :taxon_concept_metrics => [ :taxon_concept_id, :richness_score ],
          :hierarchy_entries => [ :id, :name_id, :taxon_concept_id, :published, :vetted_id, :hierarchy_id ],
          :names => [ :id, :canonical_form_id ],
          :canonical_forms => [ :id, :string ]
        }
        CollectionItem.preload_associations(collection_items, includes, :select => selects)
      end

      def preload_data_objects!(collection_items)
        return if collection_items.blank?
        includes = { :object => [ :data_type, { :toc_items => :translations } ] }
        selects = {
          :data_objects => [ :id, :object_title, :data_rating, :data_type_id ],
          :table_of_contents => 'id',
          :translated_table_of_contents => '*'
        }
        CollectionItem.preload_associations(collection_items, includes, :select => selects)
      end
    end
  end
end
