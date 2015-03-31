module EOL
  class GlobalStatistics

    # Total counts for stats on the home page
    def self.find(type)
      Rails.cache.fetch(EOL::GlobalStatistics.key_for_type(type), :expires_in => $CACHE_STATS_COUNT_IN_MINUTES.minutes) do
        count = 0
        case type
          when "taxon_concepts"
            count = EOL::GlobalStatistics.count_pages_with_content
          when "images"
            count = EOL::GlobalStatistics.count_images
          when "users" then
            count = EOL::GlobalStatistics.solr_count('User')
            count = User.where(active: true).count if count == 0
          when "collections"
            count = EOL::GlobalStatistics.solr_count('Collection')
            count = Collection.count(:conditions => 'special_collection_id IS NULL') if count == 0
          when "communities"
            count = EOL::GlobalStatistics.solr_count('Community')
            count = Community.where(published: true).count if count == 0
          when "content_partners" then
            count = ContentPartner.where(is_public: true).count
          when "data"
            count = EOL::GlobalStatistics.count_data
          else
            raise EOL::Exceptions::ObjectNotFound
        end
        count
      end
    end

    def self.count_pages_with_content
      EolStatistic.find(:last).pages_with_content rescue 0
    end

    def self.count_images
      begin
        EolStatistic.find(:last).data_objects_images
      rescue
        count = EOL::GlobalStatistics.solr_count('Image')
        count = DataObject.count(:conditions => "data_type_id=#{DataType.image.id} and published=1") if
          count == 0
      end
    end
    
    def self.count_data
      EolStatistic.new.total_data_records rescue 0
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
      Rails.cache.delete(EOL::GlobalStatistics.key_for_type(type.to_s))
    end

    def self.add_to_type(type, amount)
      old_val = Rails.cache.read(EOL::GlobalStatistics.key_for_type(type))
      return if old_val.nil?  # No need to increment if it's expired or missing.
      if old_val.to_i != old_val # The value is not a number.  Delete it (and it will get re-set later).
        EOL::GlobalStatistics.clear(type)
        return
      end
      Rails.cache.write(EOL::GlobalStatistics.key_for_type(type), old_val += amount,
                   :expires_in => $CACHE_STATS_COUNT_IN_MINUTES.minutes)
    end

    def self.key_for_type(type)
      "global_statistics/total_#{type}"
    end
  end
end
