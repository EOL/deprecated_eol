module ActiveRecord
  class Base
    class << self

      def index_with_solr(options={})
        # remove any existing callbacks in case we want to redefine the index fields
        remove_index_with_solr

        after_save :add_to_index
        before_destroy :remove_from_index
        options[:keywords] ||= []
        options[:full_text] ||= []

        define_method(:remove_from_index) do
          return unless $INDEX_RECORDS_IN_SOLR_ON_SAVE
          begin
            solr_connection = SolrAPI.new($SOLR_SERVER, $SOLR_SITE_SEARCH_CORE)
          rescue Errno::ECONNREFUSED => e
            puts "** WARNING: Solr connection failed."
            return nil
          end
          solr_connection.delete_by_query("resource_type:#{self.class.to_s} AND resource_id:#{self.id}")
        end

        define_method(:add_to_index) do
          return unless $INDEX_RECORDS_IN_SOLR_ON_SAVE
          remove_from_index
          begin
            solr_connection = SolrAPI.new($SOLR_SERVER, $SOLR_SITE_SEARCH_CORE)
          rescue Errno::ECONNREFUSED => e
            puts "** WARNING: Solr connection failed."
            return nil
          end

          self.keywords_to_send_to_solr_index.each do |params|
            solr_connection.create(params)
          end
        end

        define_method(:keywords_to_send_to_solr_index) do
          keywords_to_send_to_solr = []
          # making some exceptions for the special community and its collection which are not to be returned in searches
          return [] if self.class == Collection && self.watch_collection?
          return [] if self.class == Collection && !self.published?
          return [] if self.class == Community && !self.published?

          params = {
            'resource_type'       => self.class.to_s,
            'resource_id'         => self.id,
            'resource_unique_key' => "#{self.class}_#{self.id}"
          }
          params['date_created'] = self.created_at.solr_timestamp if self.respond_to?('created_at') && self.created_at
          params['date_modified'] = self.updated_at.solr_timestamp if self.respond_to?('updated_at') && self.updated_at

          if self.class == DataObject && !self.data_type_id.blank?
            data_type_label = self.is_video? ? 'Video' : self.data_type.label('en')
            params['resource_type'] = [self.class.to_s, data_type_label]
          end

          options[:keywords] ||= []
          options[:keywords].each do |field_or_method|
            if self.respond_to?(field_or_method)
              return_value = self.send(field_or_method)
              next if return_value.blank?
              if return_value.class == String
                keywords_to_send_to_solr << params.merge({ :keyword => return_value, :keyword_type => field_or_method })
              elsif return_value.class == Hash
                keyword_type = return_value[:keyword_type] || field_or_method
                keywords_to_send_to_solr << params.merge({ :keyword => return_value[:keywords], :keyword_type => keyword_type,
                   :language => return_value[:language], :ancestor_taxon_concept_id => return_value[:ancestor_taxon_concept_id] })
              elsif return_value.class == Array
                return_value.each do |rv|
                  keyword_type = rv[:keyword_type] || field_or_method
                  keywords_to_send_to_solr << params.merge({ :keyword => rv[:keywords], :keyword_type => keyword_type,
                    :language => rv[:language], :ancestor_taxon_concept_id => rv[:ancestor_taxon_concept_id] })
                end
              end
            else
              raise "NoMethodError: undefined method `#{field_or_method}' for #{self.class.to_s}"
            end
          end

          options[:fulltexts] ||= []
          options[:fulltexts].each do |field_or_method|
            if self.respond_to?(field_or_method)
              keyword = self.send(field_or_method)
              next if keyword.blank?
              keywords_to_send_to_solr << params.merge({ :keyword => keyword, :keyword_type => field_or_method,
                :full_text => true })
            else
              raise "NoMethodError: undefined method `#{field_or_method}' for #{self.class.to_s}"
            end
          end

          # English as default language might make sense
          keywords_to_send_to_solr.each do |k|
            k[:language] ||= 'en'
            # if k[:resource_type] == 'TaxonConcept'
            #   if k[:keyword_type] == 'PreferredName'
            #   elsif k[:keyword_type] == 'PreferredName'
            #   end
            # end
          end
          return keywords_to_send_to_solr
        end
      end

      def remove_index_with_solr
        # these methods may not exist yet and that's OK
        remove_method :add_to_index rescue nil
        remove_method :remove_from_index rescue nil
        self.after_save.delete_if{ |callback| callback.method == :add_to_index}
        self.before_destroy.delete_if{ |callback| callback.method == :remove_from_index}
      end
    end
  end
end
