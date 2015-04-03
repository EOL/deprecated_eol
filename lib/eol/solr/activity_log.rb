module EOL
  module Solr
    class ActivityLog

      # TODO - option defaults are specified all over the place (sometimes twice). Centralize and clean up.

      def self.search_with_pagination(query, options = {})
        options[:page]        ||= 1
        options[:per_page]    ||= 30
        options[:per_page]      = 30 if options[:per_page] == 0

        response = solr_search(query, options)
        total_results = response['grouped']['activity_log_unique_key']['ngroups']
        results = []
        response['grouped']['activity_log_unique_key']['groups'].each do |g|
          results << g['doclist']['docs'][0]
        end

        add_resource_instances!(results) unless options[:skip_loading_instances]
        results = WillPaginate::Collection.create(options[:page], options[:per_page], total_results) do |pager|
           pager.replace(results)
        end
        # TODO - ummmn... shouldn't we have noticed this earlier and just returned with a null collection?
        if results.length == 0
          results.total_entries = 0
        end
        results
      end

      def self.global_activities(options = {})
        options[:page]        ||= 1
        options[:per_page]    = 100

        found_user_ids = {}
        docs_to_return = []

        # we might get less than 6 non-watch list activities grouped by user, so continue paging through
        # activity logs until we have the result set we want, or until there are no more results
        while docs_to_return.length < 6
          response = solr_search('*:* NOT action_keyword:unlock', options)
          total_results = response['grouped']['activity_log_unique_key']['ngroups']
          break if total_results == 0
          results = []
          response['grouped']['activity_log_unique_key']['groups'].each do |g|
            results << g['doclist']['docs'][0]
          end

          # looking up the collections of CollectionActivities so we can remove activities on watch collections
          EOL::Solr.add_standard_instance_to_docs!(CollectionActivityLog,
            results.select{ |d| d['activity_log_type'] == 'CollectionActivityLog' }, 'activity_log_id',
            :includes => [ { :collection => [ :users ] } ],
            :selects => { :collection_activity_logs => [:id, :collection_id], :collections => [:special_collection_id], :users => [:id] }) # TODO - I don't think I did the user join correctly to work below...
          results.delete_if{ |d| d['instance'] && d['instance'].collection && d['instance'].collection.watch_collection? }

          # looking up Comments so we can remove deleted Comments
          EOL::Solr.add_standard_instance_to_docs!(Comment,
            results.select{ |d| d['activity_log_type'] == 'Comment' }, 'activity_log_id',
            :selects => { :comments => [ :id, :deleted, :parent_type ] })
          results.delete_if{ |d| d['instance'] && d['instance'].is_a?(Comment) && d['instance'].deleted? }

          # creating a list unique by user
          results.each do |r|
            unless found_user_ids[r['user_id']] # TODO - SEE ABOVE - I don't think I got the user_id like this.
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

      def self.index_notifications(base_index_hash, notification_recipient_objects)
        # TODO: is it appropriate to re-use this variable here which generally stops writing to the Logging MySQL DB
        return unless $ENABLE_DATA_LOGGING
        begin
          type_and_ids_to_send = {}
          [ Collection, Community, DataObject, TaxonConcept ].each do |klass|
            if klass_objects = notification_recipient_objects.select{ |o| o.class == klass }
              type_and_ids_to_send[klass.to_s] = klass_objects.collect{ |o| o.id }
            end
          end
          # AncestorTaxonConcept
          if ancestor_taxon_concept_ids = notification_recipient_objects.select{ |o| o.class == Hash && o[:ancestor_ids] }
            type_and_ids_to_send['AncestorTaxonConcept'] = ancestor_taxon_concept_ids.collect{ |h| h[:ancestor_ids] }.flatten
          end
          # User ACTIVITY feeds
          activity_users = notification_recipient_objects.collect do |o|
            (o.class == Hash && o[:user] && Notification.types_to_show_in_activity_feeds.include?(o[:notification_type])) ? o[:user] : nil
          end.compact
          if activity_users
            type_and_ids_to_send['User'] = activity_users.collect{ |c| c.id }
          end
          # User Newsfeeds
          users = notification_recipient_objects.collect do |o|
            if o.class == User
              o
            elsif o.class == Hash && o[:user] && !Notification.types_to_show_in_activity_feeds.include?(o[:notification_type])
              o[:user]
            else
              nil
            end
          end.compact
          if users
            type_and_ids_to_send['UserNews'] = users.collect{ |c| c.id }
          end

          solr_connection = SolrAPI.new($SOLR_SERVER, $SOLR_ACTIVITY_LOGS_CORE)
          type_and_ids_to_send.each do |feed_type, ids|
            ids = ids.uniq.delete_if{ |id| id.blank? || id == 0 }
            unless ids.blank?
              solr_connection.create(base_index_hash.dup.merge({
                'feed_type_affected' => feed_type,
                'feed_type_primary_key' => ids }))
            end
          end
        rescue Errno::ECONNREFUSED => e
          puts "** WARNING: Solr connection failed."
          return nil
        end
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
            [ { :parent => [ :flattened_ancestors, :containing_collections ] } ],
            :select => { :comments => '*', :users => [:id], :taxon_concepts => [:id], :collections => [:id] })
          comments.each do |c|
            c.log_activity_in_solr
          end

          # DataObject comments
          comments = Comment.find_all_by_id((i...(i+limit)).to_a, :conditions => "parent_type='DataObject'")
          Comment.preload_associations(comments,
            [ { :parent => [ :containing_collections,
              { :data_objects_hierarchy_entries => { :hierarchy_entry => { :taxon_concept => :flattened_ancestors } } },
              { :curated_data_objects_hierarchy_entries => :hierarchy_entry } ] } ],
            :select => { :comments => '*', :users => [:id], :data_objects => [:id], :data_objects_hierarchy_entries => '*',
              :curated_data_objects_hierarchy_entries => '*', :hierarchy_entries => [:id, :taxon_concept_id],
              :taxon_concepts => [:id], :collections => [:id] })
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

      def self.remove_watch_collection_logs
        # Retrieve collection activity logs which doesn't belongs to watch collection.
        # TODO: fix this. No need to hand-roll batch proccessing; use .find_each
        collection_activity_logs = CollectionActivityLog.
          where("c.special_collection_id = #{SpecialCollection.watch.id}").
          select('collection_activity_logs.id').
          joins("JOIN #{Collection.full_table_name} c ON (collection_activity_logs.collection_id=c.id)")
        return if collection_activity_logs.count == 0
        collection_activity_log_ids = collection_activity_logs.map(&:id).in_groups_of(1000)
        begin
          solr_connection = SolrAPI.new($SOLR_SERVER, $SOLR_ACTIVITY_LOGS_CORE)
          collection_activity_log_ids.each do |cali|
            solr_connection.delete_by_query("activity_log_type:CollectionActivityLog AND
                                             activity_log_id:(#{cali.compact.join(' OR ')})")
          end
        rescue Errno::ECONNREFUSED => e
          puts "** WARNING: Solr connection failed."
          return nil
        end
      end

    private

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
          docs.select{ |d| d['activity_log_type'] == 'CuratorActivityLog' }, 'activity_log_id',
          :includes => [ { :hierarchy_entry => [ :name, :taxon_concept, { :hierarchy => [ :agent ] } ] },
                         :user, :untrust_reasons ],
          :selects => {
            :curator_activity_logs => '*', :hiearchy => [ :agent_id ], :names => [ :string ],
            :agents => [ :full_name ], :users => '*', :untrust_reasons => '*'
          })
        EOL::Solr.add_standard_instance_to_docs!(CommunityActivityLog,
          docs.select{ |d| d['activity_log_type'] == 'CommunityActivityLog' }, 'activity_log_id')
        EOL::Solr.add_standard_instance_to_docs!(UserAddedData,
          docs.select{ |d| d['activity_log_type'] == 'UserAddedData' }, 'activity_log_id')
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
        unless options[:user] && options[:user].can_see_data?
          query += " NOT action_keyword:Trait NOT action_keyword:UserAddedData NOT activity_log_type:UserAddedData"
        end
        per_page  = options[:per_page] ? options[:per_page].to_i : 10
        page = options[:page] ? options[:page].to_i : 1
        offset = (page - 1) * per_page
        parameters = options.dup
        parameters[:sort] = options[:sort_by] || 'date_created+desc'
        parameters[:fl] = 'activity_log_type,activity_log_id,user_id,date_created'
        parameters[:group] = 'true'
        parameters['group.field'] = 'activity_log_unique_key'
        parameters['group.ngroups'] = 'true'
        parameters[:start] = offset
        parameters[:rows] = per_page
        parameters[:fq] = "date_created:[NOW/DAY-#{options[:recent_days]}DAY+TO+NOW/DAY%2B1DAY]" if options[:recent_days]
        parameters.delete_if{ |k,v| ! [ :sort, :fl, :group, 'group.field', 'group.ngroups',
                                        :start, :rows, :fq].include?(k) }
        url =  $SOLR_SERVER + $SOLR_ACTIVITY_LOGS_CORE + '/select/?wt=json&q=' + CGI.escape("{!lucene}")
        # unescaping the parameters since the brackets in :fq need to remain
        url << CGI.escape(query) << "&" << CGI.unescape(parameters.to_param())
        res = open(url).read
        JSON.load res
      end

    end
  end
end
