module EOL
  module Solr
    module SolrSearchDataObjects
      def self.tasks_for_worklist(query, options = {})
        options[:fields] = 'data_object_id'
        result = EOL::Solr.query_lucene($SOLR_SERVER + $SOLR_DATA_OBJECTS_CORE, query, options);
        data_object_ids = []
        result['response']['docs'].each{|h| data_object_ids << h['data_object_id']}
        return data_object_ids
      end
    end
  end
end
