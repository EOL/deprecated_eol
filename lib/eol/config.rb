module EOL
  class Config
    def self.clear_global_site_warning
      SiteConfigurationOption.delete_all(parameter: 'global_site_warning')
      Rails.cache.delete(cached_name_for('global_site_warning_clean'))
    end

    def self.method_missing(name, *args, &block)
      # The regex here keeps us from going into a wild loop, because cached_find called find_by_[param], which is found
      # via method_missing in the rails code!
      if SiteConfigurationOption.exists?(:parameter => name)
        eigenclass = class << self; self; end
        eigenclass.class_eval do
          define_method(name) do # Keeps us from using method_missing next time...
            param = SiteConfigurationOption.cached_find(:parameter, name, expires_in: SiteConfigurationOption::REFRESH_TIME)
            return nil unless param # This really shouldn't happen because of the #exists, but better to be safe.
            return false if param.value == 'false'
            return nil if param.value == ''
            param.value
          end
        end
        send(name)
      else
        super
      end
    end
  end
end
