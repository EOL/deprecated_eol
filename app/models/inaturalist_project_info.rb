# Create a cached hash of project information (keys are collection ids, values are hashes of parsed JSON) from
# iNaturalist.
#
# NOTE - sub-optimal that this relies on Collection for caching keys, but we don't inherit those methods. TODO -
# refactor those caching methods into a module, include them in ActiveRecord::Bas and here.
module InaturalistProjectInfo
  class << self

    # NOTE: The cache is getting populated when a JQuery call is made to collections/cache_inaturalist_projects. So a
    # common workflow would be: there is no cache, call the iNat API for one collection on collection page load, but
    # recognize the whole lot is not cached, make the JQuery call to the caching method. All subsequent requests will
    # read directly from the cache

    def get(id)
      # no need to call the iNat API when testing. This potentially saves several minutes during specs
      return nil if Rails.env.test? && !$TESTING_INATURALIST_PROJECTS
      # read from the cache only if we have one. If its not in the cache, no need to call the API again
      if InaturalistProjectInfo.cached? && !InaturalistProjectInfo.caching_in_progress?
        InaturalistProjectInfo.get_from_cache(id)
      else
        InaturalistProjectInfo.get_directly(id)
      end
    end

    def needs_caching?
      return false if InaturalistProjectInfo.cached?
      return false if InaturalistProjectInfo.caching_in_progress?
      return true
    end

    def cache_all
      # by default expire iNat cache every day. We should work with them to come up with a more precise mechanism
      Rails.cache.fetch(InaturalistProjectInfo.cache_key, expires_in: 1.day) do
        InaturalistProjectInfo.lock_caching
        InaturalistProjectInfo.get_all
      end
    rescue => e
      Rails.logger.warn "** Unable to get iNat info for ALL collections: #{e.message}"
      nil
    ensure
      InaturalistProjectInfo.unlock_caching
    end

    # The following methods should be considered private... ish. You
    # may call them, but that's not the intent. Your gun, your
    # foot. These methods are not (directly) tested and are subject to
    # change.

    def get_directly(id)
      InaturalistProjectInfo.get_inat_response(source:"#{Rails.configuration.inat_project_prefix}#{id}").first
    rescue => e
      Rails.logger.warn "** Unable to get iNat info for collection #{id}: #{e.message}"
      nil
    end

    def get_from_cache(id)
      if cached_projects = Rails.cache.read(InaturalistProjectInfo.cache_key)
        cached_projects[id]
      else
        nil
      end
    end

    def get_all
      project_info = {}
      page = 1
      until (json_response = InaturalistProjectInfo.get_inat_response(page: page)).blank?
        json_response.select {|r| r['source_url'] }.each do |i|
          if i['source_url'] =~ /eol\.org\/collections\/(\d+)/
            project_info[$1.to_i] = i
          end
        end
        page += 1
      end
      project_info
    end

    def get_inat_response(options)
      return {} unless Rails.configuration.inat_collection_url
      JSON.parse(Net::HTTP.get(URI.parse("#{Rails.configuration.inat_collection_url}?#{options.to_query}")))
    end

    def cache_key
      Collection.cached_name_for('inaturalist_project_info')
    end

    def caching_lock_key
      Collection.cached_name_for('inaturalist_project_caching_in_progress')
    end

    def cached?
      Rails.cache.exist?(InaturalistProjectInfo.cache_key)
    end

    def clear_cache
      Rails.cache.delete(InaturalistProjectInfo.cache_key)
    end

    def caching_in_progress?
      Rails.cache.exist?(InaturalistProjectInfo.caching_lock_key)
    end

    def lock_caching
      Rails.cache.fetch(InaturalistProjectInfo.caching_lock_key) { true }
    end

    def unlock_caching
      Rails.cache.delete(InaturalistProjectInfo.caching_lock_key)
    end

  end

end
