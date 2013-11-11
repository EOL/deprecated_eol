# NOTE - * IMPORTANT *
#
# Don't use this class.
#
# No, really. Don't. ...unless you know what you're doing. There are, in fact, cases where you want to modify these models
# directly, or query the table directly. But chances are good you're looking at this model simply because you want a
# configuration value. Those should be retrieved via EOL::Config.  It's a shorter name, will cache its values (for
# REFRESH_TIME), and will return intelligent values from defaults. ...Or it will return nil if there's nothing in
# the table, so you should use an "|| [defaultvalue]" after you call it (unless you're testing true/false).  Like this:
#
#   my_important_val = EOL::Config.whatever_the_parameter_is_named || :default_value
#
# ...In case you really do want the direct value from the DB, you can still call
# SiteConfigurationOption.whatever_the_parameter_is_named, but it's your gun and your foot for parsing the value. That's all.
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
  # TODO - let's move this to EOL::Config and use this as the default behavior for all of the config options (then we can keep all the rows in the DB).
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

private

  def clear_caches
    Rails.cache.delete(SiteConfigurationOption.cached_name_for("parameter/#{self.parameter}"))
  end

end
