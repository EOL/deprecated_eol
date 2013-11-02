require 'i18n' # without this, the gem will be loaded in the server but not in the console, for whatever reason

I18n.config.missing_interpolation_argument_handler = Proc.new do |key, hash, string|
  I18n.t(:missing_interpolation_argument_error)
end

# This allows some "intelligent" fallbacks for missing translations. See
# https://github.com/svenfuchs/i18n/wiki/Fallbacks
I18n::Backend::KeyValue.send(:include, I18n::Backend::Fallbacks)
# And now we switch to using Redis:
I18n.backend = I18n::Backend::KeyValue.new(Redis.new(db: 'eol_i18n'))
