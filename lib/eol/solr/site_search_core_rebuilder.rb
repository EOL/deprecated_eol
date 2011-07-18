module EOL
  module Solr
    class SiteSearchCoreRebuilder
      attr_reader :solr_api
      attr_reader :objects_to_send

      def initialize()
        @solr_api = SolrAPI.new($SOLR_SERVER, $SOLR_SITE_SEARCH_CORE)
        @objects_to_send = []
      end

      def obliterate
        @solr_api.delete_all_documents
      end
      
      def optimize
        @solr_api.optimize
      end
      
      def begin_rebuild(do_optimize = true)
        reindex_model(Community)
        reindex_model(Collection)
        reindex_model(DataObject)
        reindex_model(User)
        reindex_model(TaxonConcept)
        optimize if do_optimize
      end
      
      def reindex_model(klass)
        @solr_api.delete_by_query('resource_type:' + klass.class_name)
        first_record = klass.first
        last_record = klass.last
        return if first_record.nil? || last_record.nil?
        start = first_record.id
        max_id = last_record.id
        limit = 5000
        i = start
        while i <= max_id
          @objects_to_send = []
          case klass.class_name
          when 'Community'
            lookup_communities(i, limit);
          when 'Collection'
            lookup_collections(i, limit);
          when 'DataObject'
            lookup_data_objects(i, limit);
          when 'User'
            lookup_users(i, limit);
          when 'TaxonConcept'
            limit = 1000
            lookup_taxon_concepts(i, limit);
          end
          @objects_to_send.each do |o|
            if o[:keyword]
              o[:keyword] = SolrAPI.text_filter(o[:keyword])
            end
          end
          @solr_api.send_attributes(@objects_to_send) unless @objects_to_send.blank?
          i += limit
        end
      end
      
      def lookup_communities(start, limit)
        max = start + limit
        communities = Community.find(:all, :conditions => "id BETWEEN #{start} AND #{max}", :select => 'id, name, description, created_at, updated_at')
        communities.each do |c|
          @objects_to_send += c.keywords_to_send_to_solr_index
        end
      end
      
      def lookup_collections(start, limit)
        max = start + limit
        collections = Collection.find(:all, :conditions => "id BETWEEN #{start} AND #{max}", :select => 'id, community_id, name, description, created_at, updated_at')
        collections.each do |c|
          @objects_to_send += c.keywords_to_send_to_solr_index
        end
      end
      
      def lookup_data_objects(start, limit)
        max = start + limit
        data_objects = DataObject.find(:all, :conditions => "id BETWEEN #{start} AND #{max} AND published=1 AND visibility_id=#{Visibility.visible.id}", :select => 'id, object_title, description, data_type_id, created_at, updated_at')
        data_objects.each do |d|
          @objects_to_send += d.keywords_to_send_to_solr_index
        end
      end
      
      def lookup_users(start, limit)
        max = start + limit
        users = User.find(:all, :conditions => "id BETWEEN #{start} AND #{max} AND active=1", :select => 'id, username, given_name, family_name, created_at, updated_at')
        users.each do |u|
          @objects_to_send += u.keywords_to_send_to_solr_index
        end
      end
      
      def lookup_taxon_concepts(start, limit)
        max = start + limit
        taxon_concepts = TaxonConcept.find(:all, :conditions => "id BETWEEN #{start} AND #{max} AND published=1 AND supercedure_id=0",
          :include => [ :flattened_ancestors, { :published_hierarchy_entries => [ :name, { :scientific_synonyms => :name },
            { :common_names => [ :name, :language ] } ] } ],
          :select => { :taxon_concepts => :id, :names => :string, :languages => :iso_639_1,
            :taxon_concepts_flattened => '*' })
        taxon_concepts.each do |t|
          @objects_to_send += t.keywords_to_send_to_solr_index
        end
      end
      
      
    end
  end
end
