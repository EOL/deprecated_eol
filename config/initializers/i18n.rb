require 'i18n' # without this, the gem will be loaded in the server but not in the console, for whatever reason
# This allows some "intelligent" fallbacks for missing translations. See
# https://github.com/svenfuchs/i18n/wiki/Fallbacks
I18n::Backend::KeyValue.send(:include, I18n::Backend::Fallbacks)
# And now we switch to using Redis:
# TODO: let's use rails config rather than env here, but for now:
redhost = ENV["EOL_REDIS_HOST"] || "localhost:6379" # NOTE: those are defaults
(host, port) = redhost.split(":")
redis = Redis.new(host: host, port: port, db: 'eol_i18n')
I18n.backend = I18n::Backend::KeyValue.new(redis)

# Often we'll get these from non-default languages that haven't updated their values.
I18n.config.missing_interpolation_argument_handler = Proc.new do |key, hash, string|
  I18n.t(:missing_interpolation_argument_error)
end

lang_dir = Rails.root.join('config', 'translations')
Dir.entries(lang_dir).grep(/yml$/).each do |file|
    file_last_version = I18n.backend.store.get(file)
    file_current_version = File.mtime(File.join(lang_dir, file)).to_s
    if file_current_version != file_last_version
      translations = YAML.load_file(File.join(lang_dir, file))
      locale = translations.keys.first # There's only one.
      I18n.backend.store_translations(locale, translations[locale], escape: false)
      I18n.backend.store.set(file, file_current_version)
    end
  end
