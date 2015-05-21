# require 'i18n'
# This allows some "intelligent" fallbacks for missing translations. See
# https://github.com/svenfuchs/i18n/wiki/Fallbacks
I18n::Backend::CachedKeyValueStore.send(:include, I18n::Backend::Fallbacks)
# And now we switch to using Redis:
I18n.backend = I18n::Backend::CachedKeyValueStore.new(Redis.new(db: 'eol_i18n'))
# Often we'll get these from non-default languages that haven't updated their values.
I18n.config.missing_interpolation_argument_handler = Proc.new do |key, hash, string|
  I18n.t(:missing_interpolation_argument_error)
end