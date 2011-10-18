module EOL
  module Solr
    class ActivityLog
      
      def self.index_activities(base_index_hash, activity_logs_affected)
        # TODO: is it appropriate to re-use this variable here which generally stops writing to the Logging MySQL DB
        return unless $ENABLE_DATA_LOGGING
        begin
          solr_connection = SolrAPI.new($SOLR_SERVER, $SOLR_ACTIVITY_LOGS_CORE)
          activity_logs_affected.each do |feed_type_affected, ids|
            ids = ids.uniq.delete_if{ |id| id.blank? || id == 0 }
            unless ids.blank?
              solr_connection.create(base_index_hash.dup.merge({
                'feed_type_affected' => feed_type_affected,
                'feed_type_primary_key' => ids }))
            end
          end
        rescue Errno::ECONNREFUSED => e
          puts "** WARNING: Solr connection failed."
          return nil
        end
      end
      
      def self.search_with_pagination(query, options = {})
        options[:page]        ||= 1
        options[:per_page]    ||= 30
        options[:per_page]      = 30 if options[:per_page] == 0
        options[:group_field] ||= 'activity_log_unique_key'
        
        response = solr_search(query, options)
        total_results = response['grouped'][options[:group_field]]['ngroups']
        results = []
        response['grouped'][options[:group_field]]['groups'].each do |g|
          results << g['doclist']['docs'][0]
        end
        
        add_resource_instances!(results)
        results = WillPaginate::Collection.create(options[:page], options[:per_page], total_results) do |pager|
           pager.replace(results)
        end
        results
      end
      
      def self.global_activities(options = {})
        options[:page]        ||= 1
        options[:per_page]    = 100
        options[:group_field] = 'activity_log_unique_key'
        
        found_user_ids = {}
        docs_to_return = []
        
        # we might get less than 6 non-watch list activities grouped by user, so continue paging through
        # activity logs until we have the result set we want, or until there are no more results
        while docs_to_return.length < 6
          response = solr_search('*:*', options)
          total_results = response['grouped'][options[:group_field]]['ngroups']
          break if total_results == 0
          results = []
          response['grouped'][options[:group_field]]['groups'].each do |g|
            results << g['doclist']['docs'][0]
          end
          
          # looking up the collections of CollectionActivities so we can remove activities on watch collections
          EOL::Solr.add_standard_instance_to_docs!(CollectionActivityLog,
            results.select{ |d| d['activity_log_type'] == 'CollectionActivityLog' }, 'activity_log_id',
            :includes => [ :collection ],
            :selects => { :collection_activity_logs => [:id, :collection_id], :collections => [:special_collection_id, :user_id] })
          results.delete_if{ |d| d['instance'] && d['instance'].collection && d['instance'].collection.watch_collection? }
          
          # creating a list unique by user
          results.each do |r|
            unless found_user_ids[r['user_id']]
              docs_to_return << r
              found_user_ids[r['user_id']] = true
            end
            break if found_user_ids.length >= 6
          end
          # if we get less than 100 results there are no more pages to check
          options[:page] += 1
          break if total_results < 100
        end
        
        # adding in instances of log models
        add_resource_instances!(docs_to_return)
        
        docs_to_return
      end
      
      def self.add_resource_instances!(docs)
        EOL::Solr.add_standard_instance_to_docs!(Comment,
          docs.select{ |d| d['activity_log_type'] == 'Comment' }, 'activity_log_id',
          :includes => [ :user ],
          :selects => { :comments => '*', :users => '*' })
        EOL::Solr.add_standard_instance_to_docs!(CollectionActivityLog,
          docs.select{ |d| d['activity_log_type'] == 'CollectionActivityLog' }, 'activity_log_id',
          :includes => [ :user, :collection, :collection_item ],
          :selects => { :collection_activity_logs => '*', :users => '*', :collections => '*', :collection_items => '*' })
        EOL::Solr.add_standard_instance_to_docs!(CuratorActivityLog,
          docs.select{ |d| d['activity_log_type'] == 'CuratorActivityLog' }, 'activity_log_id')
        EOL::Solr.add_standard_instance_to_docs!(CommunityActivityLog,
          docs.select{ |d| d['activity_log_type'] == 'CommunityActivityLog' }, 'activity_log_id')
        EOL::Solr.add_standard_instance_to_docs!(UsersDataObject,
          docs.select{ |d| d['activity_log_type'] == 'UsersDataObject' }, 'activity_log_id',
          :includes => [
            { :data_object => :toc_items },
            { :taxon_concept => :published_hierarchy_entries },
            :user ],
          :selects => { :data_objects => '*', :taxon_concepts => [ :id ],
            :hierarchy_entries => '*', :users => '*' })
        
        # remove the activity log (and possibly mess with results per page and pagination)
        # if the referenced object doesn't exist
        docs.delete_if do |d|
          d['instance'].blank? ||
          (d['activity_log_type'] == 'UsersDataObject' && d['instance'].data_object.blank?)
        end
      end
      
      def self.solr_search(query, options = {})
        options[:group_field] ||= 'activity_log_unique_key'
        url =  $SOLR_SERVER + $SOLR_ACTIVITY_LOGS_CORE + '/select/?wt=json&q=' + CGI.escape(%Q[{!lucene}])
        url << CGI.escape(query)
        url << '&sort=date_created+desc&fl=activity_log_type,activity_log_id,user_id,date_created'
        url << "&group=true&group.field=#{options[:group_field]}&group.ngroups=true"

        # add paging
        limit  = options[:per_page] ? options[:per_page].to_i : 10
        page = options[:page] ? options[:page].to_i : 1
        offset = (page - 1) * limit
        url << '&start=' << URI.encode(offset.to_s)
        url << '&rows='  << URI.encode(limit.to_s)
        res = open(url).read
        JSON.load res
      end
      
      def self.rebuild_comments_logs
        start = Comment.minimum('id')
        max_id = Comment.maximum('id') + 20 # just in case some get added while this is running
        return if start.nil? || max_id.nil?
        limit = 200
        i = start
        while i < max_id
          # TaxonConcept comments
          comments = Comment.find_all_by_id((i...(i+limit)).to_a, :conditions => "parent_type='TaxonConcept'")
          Comment.preload_associations(comments,
            [ { :user => :existing_watch_collection }, { :parent => [ :flattened_ancestors, :containing_collections ] } ],
            :select => { :comments => '*', :users => [:id], :taxon_concepts => [:id], :collections => [ :id, :user_id ] })
          comments.each do |c|
            c.log_activity_in_solr
          end
          
          # DataObject comments
          comments = Comment.find_all_by_id((i...(i+limit)).to_a, :conditions => "parent_type='DataObject'")
          Comment.preload_associations(comments,
            [ { :user => :existing_watch_collection }, { :parent => [ :containing_collections,
              { :data_objects_hierarchy_entries => { :hierarchy_entry => { :taxon_concept => :flattened_ancestors } } },
              { :curated_data_objects_hierarchy_entries => :hierarchy_entry } ] } ],
            :select => { :comments => '*', :users => [:id], :data_objects => [:id], :data_objects_hierarchy_entries => '*',
              :curated_data_objects_hierarchy_entries => '*', :hierarchy_entries => [:id, :taxon_concept_id],
              :taxon_concepts => [:id], :collections => [ :id, :user_id ] })
          comments.each do |c|
            c.log_activity_in_solr
          end
          
          # Everything else (very minimal right now thus not worrying about eager loading)
          comments = Comment.find_all_by_id((i...(i+limit)).to_a, :conditions => "parent_type!='TaxonConcept' AND parent_type!='DataObject'")
          comments.each do |c|
            c.log_activity_in_solr
          end
          
          i += limit
        end
        
      end
      
    end
  end
end
