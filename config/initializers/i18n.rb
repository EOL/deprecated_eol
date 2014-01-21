require 'i18n' # without this, the gem will be loaded in the server but not in the console, for whatever reason
I18n.backend = I18nema::Backend.new
I18n::Backend::Simple.send(:include, I18n::Backend::Fallbacks)

# NOTE - JRice removed some code here.  Check 1fb9630c8ea16fedc61564cf33bc5ad9733ca472 to see it, if you want to
# reformat errors (which should probably be a TODO ).
