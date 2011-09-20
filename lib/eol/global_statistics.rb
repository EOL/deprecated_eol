module EOL
  class GlobalStatistics

    # Total counts for stats on the home page
    def self.find(type)
      $CACHE.fetch(EOL::GlobalStatistics.key_for_type(type), :expires_in => $CACHE_STATS_COUNT_IN_MINUTES.minutes) do
        case type
          when "taxon_concepts"
            TaxonConcept.has_content.count
          when "images"
            count = EOL::GlobalStatistics.solr_count('image')
            count = DataObject.count(:conditions => "data_type_id=#{DataType.image.id} and published=1") if
              count == 0
          when "users" then
            count = EOL::GlobalStatistics.solr_count('user')
            count = User.count(:conditions => "active=1") if count == 0
          when "collections"
            count = EOL::GlobalStatistics.solr_count('collection')
            count = Collection.count(:conditions => 'special_collection_id IS NULL OR user_id IS NULL') if count == 0
          when "communities"
            count = EOL::GlobalStatistics.solr_count('community')
            count = Community.count(:conditions => "published = 1") if count == 0
          when "content_partners" then
            ContentPartner.count(:conditions => "show_on_partner_page = 1")
          else
            raise EOL::Exceptions::ObjectNotFound
        end
      end
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
