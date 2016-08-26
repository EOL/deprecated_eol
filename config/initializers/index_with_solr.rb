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

          begin
            self.keywords_to_send_to_solr_index.each do |params|
              solr_connection.create(params)
            end
          rescue StandardError => e
            puts "You appear to be running a migration. Skipping index."
            return nil
          end
        end

        define_method(:keywords_to_send_to_solr_index) do
          keywords_to_send_to_solr = []
          # making some exceptions for the special community and its collection which are not to be returned in searches
          return [] if self.class == Collection && self.watch_collection?
          return [] if self.class == Collection && !self.published?
          return [] if self.class == Community && !self.published?
          return [] if self.class == User && !self.active?
          return [] if self.class == User && self.is_hidden?
          return [] if self.class == ContentPage && !self.active?

          params = {
            :resource_type        => self.class.to_s,
            :resource_id          => self.id,
            :resource_unique_key  => "#{self.class}_#{self.id}"
          }
          params[:date_created] = self.created_at.solr_timestamp if self.respond_to?('created_at') && self.created_at
          params[:date_modified] = self.updated_at.solr_timestamp if self.respond_to?('updated_at') && self.updated_at

          begin
            if self.class == DataObject && !self.data_type_id.blank?
              data_type_label = self.is_video? ? 'Video' : self.data_type.label('en')
              data_type_label = (data_type_label == 'Text' && self.is_link?) ? 'Link' : data_type_label
              params[:resource_type] = [self.class.to_s, data_type_label]
            end
          rescue StandardError => e
            puts "You appear to be running a migration. Skipping index."
            return nil
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
                additional_params = {
                  :keyword => return_value[:keywords],
                  :keyword_type => keyword_type,
                  :language => return_value[:language] }
                if return_value.include?(:ancestor_taxon_concept_id)
                  additional_params[:ancestor_taxon_concept_id] = return_value[:ancestor_taxon_concept_id]
                end
                keywords_to_send_to_solr << params.merge(additional_params)
              elsif return_value.class == Array
                return_value.each do |rv|
                  keyword_type =
                  additional_params = {
                    :keyword => rv[:keywords],
                    :keyword_type => rv[:keyword_type] || field_or_method,
                    :language => rv[:language] }
                  if rv.include?(:ancestor_taxon_concept_id)
                    additional_params[:ancestor_taxon_concept_id] = rv[:ancestor_taxon_concept_id]
                  end
                  keywords_to_send_to_solr << params.merge(additional_params)
                end
              end
            else
              raise "NoMethodError: undefined method `#{field_or_method}' for #{self.class.to_s}"
            end
          end

          options[:fulltexts] ||= []
          options[:fulltexts].each do |field_or_method|
            if self.respond_to?(field_or_method)
              return_value = self.send(field_or_method)
              next if return_value.blank?
              if return_value.class == String
                keywords_to_send_to_solr << params.merge({ :keyword => return_value, :keyword_type => field_or_method,
                  :full_text => true })
              elsif return_value.class == Array
                return_value.each do |rv|
                  keyword_type = rv[:keyword_type] || field_or_method
                  keywords_to_send_to_solr << params.merge({ :keyword => rv[:fulltexts], :keyword_type => keyword_type,
                    :language => rv[:language], :full_text => true })
                end
              end
            else
              raise "NoMethodError: undefined method `#{field_or_method}' for #{self.class.to_s}"
            end
          end

          # English as default language might make sense
          keywords_to_send_to_solr.each do |k|
            k[:language] ||= 'en'
            self.class.assign_weight!(k)
          end
          return keywords_to_send_to_solr
        end
      end

      def remove_index_with_solr
        # these methods may not exist yet and that's OK; thus the rescue nil stuff.
        remove_method :add_to_index rescue nil
        remove_method :remove_from_index rescue nil
        skip_callback :save, :after, :add_to_index rescue nil
        skip_callback :destroy, :before, :remove_from_index rescue nil
      end

      def assign_weight!(keyword)
        resource_weight = nil
        if keyword[:resource_type] == 'TaxonConcept'
          if keyword[:keyword_type] == 'PreferredScientific'
            resource_weight = 1
          elsif keyword[:keyword_type] == 'PreferredCommonName'
            resource_weight = 2
          elsif keyword[:keyword_type] == 'Synonym'
            resource_weight = 3
          elsif keyword[:keyword_type] == 'CommonName'
            resource_weight = 4
          elsif keyword[:keyword_type] == 'Surrogate'
            resource_weight = 500
          else
            resource_weight = 9
          end

        elsif keyword[:resource_type].include? 'DataObject'
          if keyword[:resource_type].include? 'Text'
            resource_weight = 40
          elsif keyword[:resource_type].include? 'Video'
            resource_weight = 50
          elsif keyword[:resource_type].include? 'Image'
            resource_weight = 60
          elsif keyword[:resource_type].include? 'Sound'
            resource_weight = 70
          else
            resource_weight = 80
          end
          # we want matches in descriptions to be shown BELOW titles
          resource_weight += 1 if keyword[:keyword_type].to_s == 'description'

        elsif keyword[:resource_type].include? 'Community'
          resource_weight = 10
        elsif keyword[:resource_type].include? 'Collection'
          resource_weight = 20
        elsif keyword[:resource_type].include? 'ContentPage'
          resource_weight = 25
        elsif keyword[:resource_type].include? 'User'
          resource_weight = 30
        elsif keyword[:resource_type].include? 'ContentPage'
          resource_weight = 25
        end

        resource_weight = 499 if resource_weight.blank?
        keyword[:resource_weight] = resource_weight
      end
    end
  end
end
