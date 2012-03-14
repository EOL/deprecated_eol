#
# Haml i18n module providing translation for all Haml plain text calls
# Idea was stolen from
# http://www.nanoant.com/programming/haml-gettext-automagic-translation
#
require 'i18n'

begin
  require 'haml' # From gem
rescue LoadError => e
  # gems:install may be run to install Haml with the skeleton plugin
  # but not the gem itself installed.
  # Don't die if this is the case.
  raise e unless defined?(Rake) && Rake.application.top_level_tasks.include?('gems:install')
end

if defined? Haml
  class Haml::Engine

    def scope_key_by_partial (key)
      prefix = @options[:filename]

      prefix = prefix.gsub(/#{Rails.root}\/app\/views\//, '')
      prefix = prefix.gsub(/\.haml/, '')
      prefix = prefix.gsub(/\/_?/, ".")
      
      prefix + key.to_s
    end

    def view_name (key)
      prefix = @options[:filename]

      prefix = prefix.gsub(/#{Rails.root}\/app\/views\//, '')
      prefix = prefix.gsub(/\/[^\/]*?\.haml/, '')
      prefix = prefix.gsub(/\/_?/, ".")
      
      prefix + key.to_s
    end

    def have_translation(key)

      # For the development environment, localize all the resources!
      # For the production - keep plain strings if no localization found.
      return true if Rails.env == 'development'

      for loc in I18n.available_locales
        opt = {}
        opt[:raise] = true
        opt[:locale] = loc
        begin
          begin
            begin
              I18n.translate(scope_key_by_partial('.' + key.to_s), opt.clone)
            rescue
              I18n.translate(view_name('.' + key.to_s), opt.clone)
            end
          rescue
            I18n.translate(key, opt.clone)
          end
          return true
        rescue
          #keys = I18n.send(:normalize_translation_keys, e.locale, e.key, e.options[:scope])
        end
      end
      # Kernel.puts('Missing translation:' + key.to_s)
      return false
    end

    #
    # Inject translate into plain text and tag plain text calls
    #
    def push_plain(text)
      if have_translation(text)
        push_script "translate('#{text.gsub(/'/, '\\\'')}')"
      else
        super(text)
      end
    end

    def parse_tag(line)
      tag_name, attributes, attributes_hash, object_ref, nuke_outer_whitespace,
        nuke_inner_whitespace, action, value = super(line)
      
      if !action and !value.empty? and have_translation(value)
        action = '='
        value = "translate('#{value.gsub(/'/, '\\\'')}')"
      end

      [tag_name, attributes, attributes_hash, object_ref, nuke_outer_whitespace,
          nuke_inner_whitespace, action, value]
    end
  end
end
