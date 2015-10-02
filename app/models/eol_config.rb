class EolConfig < ActiveRecord::Base

  self.table_name = 'site_configuration_options'

  after_create :clear_caches
  after_update :clear_caches
  validates_uniqueness_of :parameter

  # Arbitrary string (stored in cache when there is no global site warning);
  # something you would never use as a global site warning:
  EMPTY_WARNING = 'none'
  # How often you want these values to be re-checked. Shorter times mean quicker
  # changes, but more time reading the DB instead of cache.
  REFRESH_TIME = 10.minutes

  def self.create_defaults
    admin_id = User.admins.first.id rescue ''
    { email_actions_to_curators: '',
      email_actions_to_curators_address: '',
      global_site_warning: '',
      all_users_can_see_data: 'true',
      last_solr_rebuild: '',
      reference_parsing_enabled: '',
      reference_parser_pid: '',
      reference_parser_endpoint: '',
      notification_error_user_id: admin_id }.each do |key, val|
        EolConfig.create(parameter: key, value: val) unless EolConfig.exists?(parameter: key)
      end
  end

  # This one is a little different, because we need to handle nils with a cache.
  def self.global_site_warning
    cache_name = cached_name_for('global_site_warning_clean')
    if Rails.cache.exist?(cache_name)
      warning = Rails.cache.read(cache_name)
      return nil if warning == EMPTY_WARNING or warning.blank?
      warning
    else
      if EolConfig.exists?(parameter: 'global_site_warning')
        warning = EolConfig.find_by_parameter('global_site_warning').value
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
    EolConfig.delete_all(parameter: 'global_site_warning')
    Rails.cache.delete(cached_name_for('global_site_warning_clean'))
  end

  def self.method_missing(name, *args, &block)
    # The regex here keeps us from going into a wild loop, because cached_find called find_by_[param], which is found
    # via method_missing in the rails code!
    if name !~ /^find/ && EolConfig.exists?(parameter: name)
      eigenclass = class << self; self; end
      eigenclass.class_eval do
        define_method(name) do # Keeps us from using method_missing next time...
          param = cached_find(:parameter, name, expires_in: REFRESH_TIME)
          return nil unless param
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

  # NOTE: This doesn't work for site warning.
  def clear_caches
    Rails.cache.delete(EolConfig.cached_name_for("parameter/#{self.parameter}"))
  end

end
