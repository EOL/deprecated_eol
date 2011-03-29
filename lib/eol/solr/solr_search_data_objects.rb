module EOL
  module Solr
    module SolrSearchDataObjects
      def self.images_for_concept(query, options = {})
        options[:fields] = 'data_object_id'
        result = EOL::Solr.query_lucene($SOLR_SERVER + $SOLR_DATA_OBJECTS_CORE, query, options);
        data_object_ids = []
        result['response']['docs'].each{|h| data_object_ids << h['data_object_id'][0]}
        return data_object_ids
      end
    end
  end
end
