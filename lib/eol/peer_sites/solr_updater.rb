module EOL
  module PeerSites
    class SolrUpdater

      def self.update
        logs_needing_to_be_run = SolrLog.find_by_sql("SELECT sl.*
          FROM solr_logs sl
          LEFT JOIN solr_log_statuses sls ON (sl.id=sls.solr_log_id and sls.peer_site_id=#{PEER_SITE_ID})
          WHERE sl.peer_site_id!=#{PEER_SITE_ID} AND sls.id IS NULL")
        logs_needing_to_be_run.each do |solr_log|
          pp solr_log
          case solr_log.core
          when 'activity_logs'
            update_activity_logs(solr_log)
          when 'bhl'
            # nothing yet
          when 'collection_items'
            update_collection_items(solr_log)
          when 'data_objects'
            update_data_objects(solr_log)
          when 'site_search'
            update_site_search(solr_log)
          else
            puts "I dont know what to do with core #{solr_log.core}"
          end
        end
      end

      def self.update_activity_logs(solr_log)
        case solr_log.object_type
        when 'Comment'
          if solr_log.action == 'update'
            solr_log.object.log_activity_in_solr(:solr_log => solr_log)
          elsif solr_log.action == 'delete'
            solr_log.object.hide(:solr_log => solr_log)
          end
        when 'DataObject'
          if solr_log.action == 'update'
            solr_log.object.log_activity_in_solr(:solr_log => solr_log)
          end
        when 'CollectionActivityLog'
          if solr_log.action == 'update'
            solr_log.object.log_activity_in_solr(:solr_log => solr_log)
          end
        when 'CommunityActivityLog'
          if solr_log.action == 'update'
            solr_log.object.log_activity_in_solr(:solr_log => solr_log)
          end
        when 'CuratorActivityLog'
          if solr_log.action == 'update'
            solr_log.object.log_activity_in_solr(:solr_log => solr_log)
          end
        when 'User'
          if solr_log.action == 'delete'
            solr_log.object.destroy_comments(:solr_log => solr_log)
          end
        else
          puts "I dont know what to do with ActivityLogs : #{solr_log.object_type}"
        end
      end

      def self.update_collection_items(solr_log)
        case solr_log.action
        when 'update'
          solr_log.object.index_collection_item_in_solr(:solr_log => solr_log)
        when 'delete'
          solr_log.object.remove_collection_item_from_solr(:solr_log => solr_log)
        else
          puts "I dont know what to do with CollectionItems : #{solr_log.action}"
        end
      end

      def self.update_data_objects(solr_log)
        case solr_log.action
        when 'update'
          EOL::Solr::DataObjectsCoreRebuilder.reindex_single_object(solr_log.object, :solr_log => solr_log)
        when 'delete'
          EOL::Solr::DataObjectsCoreRebuilder.delete_single_object(solr_log.object.id, :solr_log => solr_log)
        else
          puts "I dont know what to do with DataObjects : #{solr_log.action}"
        end
      end

      def self.update_site_search(solr_log)
        object_types_site_search_knows_about = ['Collection', 'Community', 'ContentPage', 'DataObject', 'TaxonConcept', 'User']
        unless object_types_site_search_knows_about.include?(solr_log.object_type)
          puts "I dont know what to do with SiteSearch : #{solr_log.object_type}"
          return
        end
        if solr_log.action == 'update'
          solr_log.object.add_to_index(:solr_log => solr_log)
        elsif solr_log.action == 'delete'
          solr_log.object.remove_from_index(:solr_log => solr_log)
        end
      end

    end
  end
end