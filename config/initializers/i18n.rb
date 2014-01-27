require 'i18n' # without this, the gem will be loaded in the server but not in the console, for whatever reason

I18n::Backend::Simple.send(:include, I18n::Backend::Fallbacks)

# Often we'll get these from non-default languages that haven't updated their values.
I18n.config.missing_interpolation_argument_handler = Proc.new do |key, hash, string|
  I18n.t(:missing_interpolation_argument_error)
end
