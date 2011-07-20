require 'i18n' # without this, the gem will be loaded in the server but not in the console, for whatever reason

module I18n
  class MissingTranslationData < ArgumentError
    attr_reader :locale, :key, :options
    def initialize(locale, key, opts = nil)
      @key, @locale, @options = key, locale, opts || {}
      if @locale == :en
        keys = I18n.normalize_keys(locale, key, options[:scope])
        keys << 'no key' if keys.size < 2
        super key
      else
        translated_string = I18n.t(key, opts, :locale => :en)
        begin
          # replacing variables
          for opt in opts
            translated_string = translated_string.gsub('%{' + opt[0].to_s + '}', opt[1].to_s) if !translated_string.index('%{' + opt[0].to_s + '}').nil?
          end
        rescue
          translated_string = key
        end        
        super translated_string
      end
    end
  end
end