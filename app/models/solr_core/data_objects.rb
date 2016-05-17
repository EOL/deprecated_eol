class SolrCore
  class DataObjects < SolrCore::Base
    CORE_NAME = "data_objects"

    def initialize
      connect(CORE_NAME)
    end

    def best_image_for_page(id)
      paginate("taxon_concept_id:#{id} AND "\
        "data_type_id:#{DataType.image_type_ids.join(" OR data_type_id:")} AND "\
        "published:1 AND visible_ancestor_id:#{id} AND "\
        "(trusted_ancestor_id:#{id} OR unreviewed_ancestor_id:#{id})",
        sort: ["max_visibility_weight desc",
          "max_vetted_weight desc",
          "data_rating desc"],
        per_page: 1)["response"]["docs"].first
    end

    def reindex_hashes(items)
      items = Array(items)
      EOL.log("SolrCore::DataObjets#reindex_hashes (#{items.size} items)", prefix: '.')
      delete(items.map { |i| "data_object_id:#{i[:data_object_id]}" })
      @connection.add(items)
      @connection.commit
    end
  end
end
