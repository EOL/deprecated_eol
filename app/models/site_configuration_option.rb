class SiteConfigurationOption < ActiveRecord::Base

  after_create :clear_caches
  after_update :clear_caches
  validates_uniqueness_of :parameter

  # Arbitrary string (stored in cache when there is no global site warning); something you would never use as a global site warning:
  EMPTY_WARNING = 'none'
  # How often you want these values to be re-checked. Shorter times mean quicker changes, but more time reading the DB instead of cache.
  REFRESH_TIME = 10.minutes

  include NamedDefaults

  set_defaults :parameter,
    [ { parameter: :email_actions_to_curators },
      { parameter: :email_actions_to_curators_address},
      { parameter: :global_site_warning},
      { parameter: :all_users_can_see_data, value: 'false'},
      { parameter: :reference_parsing_enabled},
      { parameter: :reference_parser_pid},
      { parameter: :reference_parser_endpoint},
      { parameter: :notification_error_user_id}
    ],
    default_params: { value: '' }

  # This one is a little different, because we need to handle nils with a cache.
  def self.global_site_warning
    cache_name = cached_name_for('global_site_warning_clean')
    if Rails.cache.exist?(cache_name)
      warning = Rails.cache.read(cache_name)
      return nil if warning == EMPTY_WARNING or warning.blank?
      warning
    else
      if SiteConfigurationOption.exists?(parameter: 'global_site_warning')
        warning = SiteConfigurationOption.find_by_parameter('global_site_warning').value
        warning = EMPTY_WARNING if warning.blank?
        Rails.cache.write(cache_name, warning, expires_in: REFRESH_TIME)
        return nil if warning == EMPTY_WARNING
        warning
      else
        Rails.cache.write(cache_name, EMPTY_WARNING, expires_in: REFRESH_TIME)
        return nil
      end
    end
  end

  def self.clear_global_site_warning
    SiteConfigurationOption.delete_all(parameter: 'global_site_warning')
    Rails.cache.delete(cached_name_for('global_site_warning_clean'))
  end

  def self.method_missing(name, *args, &block)
    # The regex here keeps us from going into a wild loop, because cached_find called find_by_[param], which is found
    # via method_missing in the rails code!
    if name !~ /^find/ && SiteConfigurationOption.exists?(:parameter => name)
      eigenclass = class << self; self; end
      eigenclass.class_eval do
        define_method(name) do # Keeps us from using method_missing next time...
          param = cached_find(:parameter, name, expires_in: REFRESH_TIME)
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

private

  def clear_caches
    Rails.cache.delete(SiteConfigurationOption.cached_name_for("parameter/#{self.parameter}"))
  end

end
