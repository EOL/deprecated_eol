module EOL
  module Solr
    class TraitsCoreRebuilder
      def self.connect
        SolrAPI.new($SOLR_SERVER2, $SOLR_TRAIT_CORE)
      end

      def self.obliterate
        solr_api = self.connect
        solr_api.delete_all_documents
      end

      
      def self.remove_data_object(trait)
        api = SolrAPI.new($SOLR_SERVER2, $SOLR_TRAIT_CORE)
        api.delete_by_query("trait_id:#{trait.trait_id}")
      end
      
    
     def self.reindex_single_object(trait)
        begin
          solr_connection = self.connect
          solr_connection.delete_by_id(trait.trait_id)
          solr_connection.create(solr_schema_data_hash(trait))
          return true
        rescue
        end
        return false
      end

      def self.solr_schema_data_hash(trait)
        hash = {
          'trait_id' =>trait.trait_id,
          'taxon_concept_id' =>trait.taxon_concept_id,
          'predicate_label' =>trait.predicate_label,
          'predicate_uri'  =>trait.predicate_uri,
          'stat_method_literal' =>trait.stat_method_literal,
          'value_literal' =>trait.value_literal,
          'value_uri' =>trait.value_uri,
          'value_id' =>trait.value_id,
          'unit_literal' =>trait.unit_literal,
          'source_name'  =>trait.source_name
         
        }
      
        # clean up and use unique values
        hash.each do |k, v|
          if v.class == Array
            v.delete(0)
            v.uniq!
            v.compact!
          end
        end

      
        return hash
      end
    end
  end
end
