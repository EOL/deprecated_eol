module EOL
  module LocalCacheable

    # This method essentially is a wrapper for:
    #     Rails.cache.fetch(key, options) do { block }
    #
    # It create a class variable with the same key, and another to hold
    # the last time it updated. After the timeout, it will run another Rails.cache.fetch
    def cache_fetch_with_local_timeout(key, options = {}, &block)
      cache_locally_with_key(key, options) do
        Rails.cache.fetch(key, options) do
          yield
        end
      end
    end

    # This method performs in the same way, but with the `cached`
    # method that we have on ActiveRecord::Base
    def cached_with_local_timeout(key, options = {}, &block)
      if self < ActiveRecord::Base
        cache_locally_with_key(key, options) do
          cached(key, options) do
            yield
          end
        end
      end
    end

    def cache_locally_with_key(key, options = {}, &block)
      options[:timeout] ||= 60  # 1 minute. Doesn't need to be long to save lots of Memcached calls
      key.gsub!(/[^a-z0-9]/i, '_')
      class_variable_set("@@#{key}", nil) unless class_variable_defined?("@@#{key}")
      class_variable_set("@@#{key}_last_cache", 1.year.ago) unless class_variable_defined?("@@#{key}_last_cache")
      if class_variable_get("@@#{key}") && ((Time.now - class_variable_get("@@#{key}_last_cache")) < options[:timeout]) && ! Rails.env.test?
        return class_variable_get("@@#{key}")
      end
      class_variable_set("@@#{key}", yield)
      class_variable_set("@@#{key}_last_cache", Time.now)
      class_variable_get("@@#{key}")
    end

  end
end
