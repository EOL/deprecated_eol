module EOL
  module Solr
    class SiteSearchCoreRebuilder

      def self.connect
        SolrAPI.new($SOLR_SERVER, $SOLR_SITE_SEARCH_CORE)
      end

      def self.obliterate
        solr_api = self.connect
        solr_api.delete_all_documents
      end

      def self.begin_rebuild(options = {})
        options[:optimize] = true unless defined?(options[:optimize])
        solr_api = self.connect
        solr_api.delete_all_documents

        self.reindex_model(Community, solr_api)
        self.reindex_model(Collection, solr_api)
        self.reindex_model(DataObject, solr_api)
        self.reindex_model(User, solr_api)
        self.reindex_model(TaxonConcept, solr_api)
        self.reindex_model(ContentPage, solr_api)
        EOL::Solr::SiteSearch.rebuild_spelling_suggestions
        solr_api.optimize if options[:optimize]
      end

      def self.reindex_model(klass, solr_api)
        solr_api.delete_by_query('resource_type:' + klass.name)
        start = klass.minimum('id') || 0
        max_id = klass.maximum('id') || 0
        return if max_id == 0
        limit = 500
        i = start
        objects_to_send = []
        while i <= max_id
          objects_to_send = []
          case klass.name
          when 'Community'
            objects_to_send += self.lookup_communities(i, limit);
          when 'Collection'
            objects_to_send += self.lookup_collections(i, limit);
          when 'DataObject'
            objects_to_send += self.lookup_data_objects(i, limit);
          when 'User'
            objects_to_send += self.lookup_users(i, limit);
          when 'TaxonConcept'
            objects_to_send += self.lookup_taxon_concepts(i, limit);
          when 'ContentPage'
            objects_to_send += self.lookup_content_pages(i, limit);
          end
          objects_to_send.each do |o|
            if o[:keyword].class == String
              o[:keyword] = SolrAPI.text_filter(o[:keyword])
            elsif o[:keyword].class == Array
              o[:keyword].map!{ |k| SolrAPI.text_filter(k) }
            end
          end
          unless objects_to_send.blank?
            solr_api.create(objects_to_send)
          end
          i += limit
        end
      end

      def self.lookup_communities(start, limit)
        max = start + limit
        objects_to_send = []
        communities = Community.where("id BETWEEN #{start} AND #{max}").select('id, name, description, created_at, updated_at, published')
        communities.each do |c|
          objects_to_send += c.keywords_to_send_to_solr_index
        end
        objects_to_send
      end

      def self.lookup_collections(start, limit)
        max = start + limit
        objects_to_send = []
        # TODO - this should include the users and collections, I think.
        collections = Collection.where("id BETWEEN #{start} AND #{max}").select('id, name, description, created_at, updated_at, special_collection_id, published')
        collections.each do |c|
          objects_to_send += c.keywords_to_send_to_solr_index
        end
        objects_to_send
      end

      def self.lookup_data_objects(start, limit)
        max = start + limit
        objects_to_send = []
        # TODO - Modify this to return only visible data objects
        data_objects = DataObject.
          where("id BETWEEN #{start} AND #{max} AND published=1").
          select('id, object_title, description, data_type_id, data_subtype_id,
            created_at, updated_at, rights_holder, rights_statement,
            bibliographic_citation, location')
        data_objects.each do |d|
          objects_to_send += d.keywords_to_send_to_solr_index
        end
        objects_to_send
      end

      def self.lookup_users(start, limit)
        max = start + limit
        objects_to_send = []
        users = User.where("id BETWEEN #{start} AND #{max} AND active=1").select('id, username, given_name, family_name, curator_level_id, created_at, updated_at, active, hidden')
        users.each do |u|
          objects_to_send += u.keywords_to_send_to_solr_index
        end
        objects_to_send
      end

      def self.lookup_content_pages(start, limit)
        max = start + limit
        objects_to_send = []
        content_pages = ContentPage.where("id BETWEEN #{start} AND #{max} AND active=1")
        content_pages.each do |cp|
          objects_to_send += cp.keywords_to_send_to_solr_index
        end
        objects_to_send
      end

      def self.lookup_taxon_concepts(start, limit)
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
        objects_to_send = []
        taxon_concepts = TaxonConcept.find(:all, :conditions => "id BETWEEN #{start} AND #{max} AND published=1 AND supercedure_id=0",
          :include => [ :flattened_ancestors, { :published_hierarchy_entries => [ :name, { :scientific_synonyms => :name },
            { :common_names => [ :name, :language ] } ] } ],
          :select => { :taxon_concepts => :id, :names => [ :string, :ranked_canonical_form_id ], :languages => :iso_639_1,
            :flat_taxa => '*', :hierarchy_entries => [ :published, :visibility_id ] })
        taxon_concepts.each do |t|
          objects_to_send += t.keywords_to_send_to_solr_index
        end
        objects_to_send
      end

    end
  end
end
