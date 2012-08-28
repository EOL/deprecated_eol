module EOL
  module Solr
    class CollectionItemsCoreRebuilder

      def self.connect
        SolrAPI.new($SOLR_SERVER, $SOLR_COLLECTION_ITEMS_CORE)
      end

      def self.obliterate
        solr_api = self.connect
        solr_api.delete_all_documents
      end

      def self.begin_rebuild(options = {})
        options[:optimize] = true unless defined?(options[:optimize])
        solr_api = self.connect
        solr_api.delete_all_documents
        self.start_to_index_collection_items(solr_api)
        solr_api.optimize if options[:optimize]
      end

      def self.reindex_collection_items_by_ids(ids)
        return if ids.empty?
        solr_api = self.connect
        objects_to_send = self.lookup_collection_items(ids);
        objects_to_send.each do |o|
          o['title'] = SolrAPI.text_filter(o['title']) if o['title']
          o['annotation'] = SolrAPI.text_filter(o['annotation']) if o['annotation']
        end
        unless objects_to_send.blank?
          solr_api.create(objects_to_send)
        end
      end

      def self.start_to_index_collection_items(solr_api)
        start = CollectionItem.first.id rescue 0
        max_id = CollectionItem.last.id rescue 0
        return if max_id == 0
        limit = 500
        i = start
        while i <= max_id
          objects_to_send = []
          objects_to_send += self.lookup_collection_items(i, limit);
          objects_to_send.each do |o|
            o['title'] = SolrAPI.text_filter(o['title']) if o['title']
            o['annotation'] = SolrAPI.text_filter(o['annotation']) if o['annotation']
          end
          unless objects_to_send.blank?
            solr_api.create(objects_to_send)
          end
          i += limit
        end
      end

      def self.lookup_collection_items(start, limit = 500)
        objects_to_send = []
        if start.class == Array
          collection_items = CollectionItem.find_all_by_id(start)
        else
          max = start + limit
          collection_items = CollectionItem.find(:all, :conditions => "id BETWEEN #{start} AND #{max}")
        end
        self.preload_concepts_and_objects!(collection_items)
        collection_items.each do |i|
          begin
            hash = i.solr_index_hash
            objects_to_send << hash
          rescue EOL::Exceptions::InvalidCollectionItemType => e
            Rails.logger.error "** EOL::Solr::CollectionItemsCoreRebuilder: #{e.message}"
            puts "** #{e.message}"
          end
        end
        objects_to_send
      end

      def self.preload_concepts_and_objects!(collection_items)
        self.preload_object!(collection_items.select{ |d| d.object_type == 'Community' })
        self.preload_object!(collection_items.select{ |d| d.object_type == 'Collection' })
        self.preload_object!(collection_items.select{ |d| d.object_type == 'User' })
        self.preload_taxon_concepts!(collection_items.select{ |d| d.object_type == 'TaxonConcept' })
        self.preload_data_objects!(collection_items.select{ |d| ['Image', 'Video', 'Sound', 'Text', 'Link', 'DataObject'].include?(d.object_type) })
      end

      def self.preload_object!(collection_items)
        return if collection_items.blank?
        CollectionItem.preload_associations(collection_items, :object)
      end

      def self.preload_taxon_concepts!(collection_items)
        return if collection_items.blank?
        includes = { :object => [ :taxon_concept_metric,
          { :published_hierarchy_entries => { :name => :canonical_form } },
          { :preferred_entry => 
            { :hierarchy_entry => { :name => :canonical_form } } } ] }
        selects = {
          :taxon_concepts => 'id',
          :taxon_concept_metrics => [ :taxon_concept_id, :richness_score ],
          :taxon_concept_preferred_entries => '*',
          :hierarchy_entries => [ :id, :name_id, :taxon_concept_id, :published, :vetted_id, :hierarchy_id ],
          :names => [ :id, :string, :italicized, :canonical_form_id ],
          :canonical_forms => [ :id, :string ]
        }
        CollectionItem.preload_associations(collection_items, includes, :select => selects)
      end

      def self.preload_data_objects!(collection_items)
        return if collection_items.blank?
        includes = { :object => [ :data_type, :link_type, { :toc_items => :translations } ] }
        selects = {
          :data_objects => [ :id, :object_title, :data_rating, :data_type_id, :link_type_id ],
          :table_of_contents => 'id',
          :translated_table_of_contents => '*'
        }
        CollectionItem.preload_associations(collection_items, includes, :select => selects)
      end
    end
  end
end
