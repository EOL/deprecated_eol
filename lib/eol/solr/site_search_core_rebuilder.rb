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
        @solr_api.optimize
      end

      def optimize
        @solr_api.optimize
      end

      def begin_rebuild(do_optimize = false)
        reindex_model(Community)
        reindex_model(Collection)
        reindex_model(DataObject)
        reindex_model(User)
        reindex_model(TaxonConcept)
        optimize if do_optimize
      end

      def reindex_model(klass)
        @solr_api.delete_by_query('resource_type:' + klass.class_name)
        start = klass.minimum('id')
        max_id = klass.maximum('id') # doing this to avoid TC supercedure
        return if start.nil? || max_id.nil?
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
            if o[:keyword].class == String
              o[:keyword] = SolrAPI.text_filter(o[:keyword])
            elsif o[:keyword].class == Array
              o[:keyword].map!{ |k| SolrAPI.text_filter(k) }
            end
          end
          @solr_api.send_attributes(@objects_to_send) unless @objects_to_send.blank?
          i += limit
        end
      end

      def lookup_communities(start, limit)
        max = start + limit
        communities = Community.find(:all, :conditions => "id BETWEEN #{start} AND #{max}", :select => 'id, name, description, created_at, updated_at, published')
        communities.each do |c|
          @objects_to_send += c.keywords_to_send_to_solr_index
        end
      end

      def lookup_collections(start, limit)
        max = start + limit
        # TODO - this should include the users and collections, I think.
        collections = Collection.find(:all, :conditions => "id BETWEEN #{start} AND #{max}", :select => 'id, name, description, created_at, updated_at, special_collection_id, published')
        collections.each do |c|
          @objects_to_send += c.keywords_to_send_to_solr_index
        end
      end

      def lookup_data_objects(start, limit)
        max = start + limit
        # TODO - Modify this to return only visible data objects
        data_objects = DataObject.find(:all, :conditions => "id BETWEEN #{start} AND #{max} AND published=1", :select => 'id, object_title, description, data_type_id, created_at, updated_at')
        data_objects.each do |d|
          @objects_to_send += d.keywords_to_send_to_solr_index
        end
      end

      def lookup_users(start, limit)
        max = start + limit
        users = User.find(:all, :conditions => "id BETWEEN #{start} AND #{max} AND active=1", :select => 'id, username, given_name, family_name, curator_level_id, created_at, updated_at')
        users.each do |u|
          @objects_to_send += u.keywords_to_send_to_solr_index
        end
      end

      def lookup_taxon_concepts(start, limit)
        # max = start + limit
        # taxon_concept_ids_array = TaxonConcept.connection.select_values("SELECT tc.id, tc.vetted_id, tcn.preferred, tcn.vern, tcn.language_id, tcn.source_hierarchy_entry_id, n.string FROM taxon_concepts tc LEFT JOIN (taxon_concept_names tcn JOIN names n ON  (tcn.name_id=n.id)) ON (tc.id=tcn.taxon_concept_id) WHERE tc.supercedure_id=0 AND tc.published=1 AND tc.id  BETWEEN #{start} AND #{max}")
        #
        # # ,
        # #   :include => [
        # #     :flattened_ancestors,
        # #     { :published_hierarchy_entries => [
        # #       :name, { :scientific_synonyms => :name } ] },
        # #     { :denormalized_common_names => :name } ],
        # #   :select => { :taxon_concepts => :id, :names => [ :string, :ranked_canonical_form_id ], :languages => :iso_639_1,
        # #     :taxon_concepts_flattened => '*' })
        # # taxon_concepts.each do |t|
        # #   @objects_to_send += t.keywords_to_send_to_solr_index
        # # end
        #
        #
        # return
        max = start + limit
        taxon_concepts = TaxonConcept.find(:all, :conditions => "id BETWEEN #{start} AND #{max} AND published=1 AND supercedure_id=0",
          :include => [ :flattened_ancestors, { :published_hierarchy_entries => [ :name, { :scientific_synonyms => :name },
            { :common_names => [ :name, :language ] } ] } ],
          :select => { :taxon_concepts => :id, :names => [ :string, :ranked_canonical_form_id ], :languages => :iso_639_1,
            :taxon_concepts_flattened => '*', :hierarchy_entries => [ :published, :visibility_id ] })
        taxon_concepts.each do |t|
          @objects_to_send += t.keywords_to_send_to_solr_index
        end

      end


    end
  end
end
