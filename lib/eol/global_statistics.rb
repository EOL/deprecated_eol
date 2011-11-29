module EOL
  class GlobalStatistics

    # Total counts for stats on the home page
    def self.find(type)
      $CACHE.fetch(EOL::GlobalStatistics.key_for_type(type), :expires_in => $CACHE_STATS_COUNT_IN_MINUTES.minutes) do
        count = 0
        case type
          when "taxon_concepts"
            count = EOL::GlobalStatistics.count_pages_with_content
          when "images"
            count = EOL::GlobalStatistics.solr_count('Image')
            count = DataObject.count(:conditions => "data_type_id=#{DataType.image.id} and published=1") if
              count == 0
          when "users" then
            count = EOL::GlobalStatistics.solr_count('User')
            count = User.count(:conditions => "active=1") if count == 0
          when "collections"
            count = EOL::GlobalStatistics.solr_count('Collection')
            count = Collection.count(:conditions => 'special_collection_id IS NULL') if count == 0
          when "communities"
            count = EOL::GlobalStatistics.solr_count('Community')
            count = Community.count(:conditions => "published = 1") if count == 0
          when "content_partners" then
            count = ContentPartner.count(:conditions => "public = 1")
          else
            raise EOL::Exceptions::ObjectNotFound
        end
        count
      end
    end

    def self.count_pages_with_content
      # # This query uses the DataObjects table directly to get a more accurate number, but it takes from 30-50 seconds
      # TaxonConcept.connection.execute("select count(*) from ((select distinct taxon_concept_id from data_objects_hierarchy_entries dohe join data_objects do on (dohe.data_object_id=do.id) join hierarchy_entries he on (dohe.hierarchy_entry_id=he.id) where do.published=1 and dohe.visibility_id=1 and he.published=1) UNION DISTINCT (select distinct taxon_concept_id from users_data_objects udo join data_objects do on (udo.data_object_id=do.id) where udo.visibility_id=1 and do.published=1) UNION DISTINCT (select distinct taxon_concept_id from curated_data_objects_hierarchy_entries cdohe join data_objects do on (cdohe.data_object_id=do.id) join hierarchy_entries he on (cdohe.hierarchy_entry_id=he.id) where do.published=1 and cdohe.visibility_id=1 and he.published=1)) counts").fetch_row.first.to_i
      
      # This query uses the cache table for faster but slightly out-of-date (by up to a day or two) numbers
      TaxonConceptMetric.connection.execute("
        SELECT count(*) FROM taxon_concept_metrics
        WHERE image_total > 0
        OR text_total > 0
        OR video_total > 0
        OR sound_total > 0
        OR flash_total > 0
        OR youtube_total > 0
        OR user_submitted_text > 0").fetch_row.first.to_i
    end

    def self.solr_count(type)
      EOL::Solr::SiteSearch.search_with_pagination('*', {:type => [type]})[:results].total_entries
    end

    def self.increment(type)
      EOL::GlobalStatistics.add_to_type(type, 1)
    end

    def self.decrement(type)
      EOL::GlobalStatistics.add_to_type(type, -1)
    end

    def self.clear(type)
      $CACHE.delete(EOL::GlobalStatistics.key_for_type(type))
    end

    def self.add_to_type(type, amount)
      old_val = $CACHE.read(EOL::GlobalStatistics.key_for_type(type))
      return if old_val.nil?  # No need to increment if it's expired or missing.
      if old_val.to_i != old_val # The value is not a number.  Delete it (and it will get re-set later).
        EOL::GlobalStatistics.clear(type)
        return
      end
      $CACHE.write(EOL::GlobalStatistics.key_for_type(type), old_val += amount,
                   :expires_in => $CACHE_STATS_COUNT_IN_MINUTES.minutes)
    end

    def self.key_for_type(type)
      "global_statistics/total_#{type}"
    end
  end
end
