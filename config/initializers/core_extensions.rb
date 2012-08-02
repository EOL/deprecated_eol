Rails.cache.||= Rails.cache

class String

  # Normalize a string for better matching, e.g. for searches
  def normalize
    # Remember, inline regexes can leak memory.  Storing as variables avoids this.
    @@normalization_regex ||= /[;:,\.\(\)\[\]\!\?\*_\\\/\"\']/
    @@spaces_regex        ||= /\s+/
    @@tag_regex           ||= /<[^>]*>/
    name = self.clone
    return name.downcase.gsub(@@normalization_regex, '').gsub(@@tag_regex, '').gsub(@@spaces_regex, ' ')
    return name.downcase.gsub(@@normalization_regex, '').gsub(@@spaces_regex, ' ')
  end

  # Not all languages can "safely" downcase.  For example, in German, it's quite awkward to downcase nouns.  So:
  def safe_downcase
    return self unless I18n && I18n.locale && [:en, :es, :fr].include?(I18n.locale)
    return self.downcase
  end

  def strip_italics
    self.gsub(/<\/?i>/i, "")
  end

  def underscore_non_word_chars
    @@non_word_chars_regex ||= /[^A-Za-z0-9\/]/
    @@dup_underscores_regex ||= /__+/
    string = self.clone
    string.gsub(@@non_word_chars_regex, '_').gsub(@@dup_underscores_regex, '_')
  end
  
  def capitalize_all_words_if_using_english
    if I18n.locale == 'en' || I18n.locale == :en
      # This is only safe in English:
      capitalize_all_words
    else
      self
    end
  end
  
  def capitalize_all_words
    string = self.clone
    unless string.blank?
      string = string.split(/ /).map {|w| w.firstcap }.join(' ')
    end
    string
  end
  
end

module ActiveRecord
  class Base
    class << self

      # options is there so that we can pass in the :serialize => true option in the cases where we were using Yaml...
      # I am going to try NOT doing anything with that option right now, to see if it works.  If not, however, I want
      # to at least have it passed in when we needed it, so the code can change later if needed.
      def cached_find(field, value, options = {})
        key = "#{field}/#{value}"
        #look locally first then in Memcached
        if $USE_LOCAL_CACHE_CLASSES && r = check_local_cache(key)
          return r.dup
        end

        r = cached(key, options) do
          r = send("find_by_#{field}", value, :include => options[:include])
        end
        set_local_cache(key, r)
        r
      end

      def cached_read(key)
        name = cached_name_for(key)
        # TODO: to avoid the => undefined class/module Agent - type of errors when reading
        # cached instances with associations preloaded. Very hacky, I apologize
        if !Rails.configuration.cache_classes && defined?(self::CACHE_ALL_ROWS_DEFAULT_INCLUDES)
          if self.name == 'Hierarchy'
            Agent
            Resource
            ContentPartner
            User
          elsif self.name == 'TocItem'
            InfoItem
          elsif self.name == 'InfoItem'
            TocItem
          end
        end
        Rails.cache.read(name)
      end

      def delete_cached(field, value)
        self.reset_cached_instances # TODO - we really DON'T want to do this (I don't think)... we would rather replace the single instance required...
        # TODO - I just don't understand where these variables are even being written to memcached... but whatever is
        # handling that should also handle this...  Sooooo... move this to where it belongs.
        Rails.cache.delete(self.cached_name_for("instance_#{field}_#{value}"))
      end

      def cached_with_local_cache(key, options = {}, &block)
        if $USE_LOCAL_CACHE_CLASSES && r = check_local_cache(key)
          return r.dup
        end
        r = cached(key, options, &block)
        set_local_cache(key, r)
        r
      end

      def cached(key, options = {}, &block)
        name = cached_name_for(key)
        if Rails.cache.# Sometimes during tests, cache has not yet been initialized.
          Rails.cache.fetch(name) do
            yield
          end
        else
          yield
        end
      end

      def cached_name_for(key)
        "#{Rails.env}/#{self.table_name}/#{key.underscore_non_word_chars}"[0..249]
      end

      def check_local_cache(key)
        initialize_cached_instances
        if local_cache = class_variable_get(:@@cached_instances)
          return local_cache[key]
        end
      end
      def set_local_cache(key, value)
        initialize_cached_instances
        if local_cache = class_variable_get(:@@cached_instances)
          local_cache[key] = value
        end
      end
      def initialize_cached_instances
        unless class_variable_defined?(:@@cached_instances)
          class_variable_set(:@@cached_instances, {})
        end
      end
      def reset_cached_instances
        if class_variable_defined?(:@@cached_instances)
          class_variable_set(:@@cached_instances, {})
        end
        if class_variable_defined?(:@@cached_all_instances)
          class_variable_set(:@@cached_all_instances, false)
        end
      end

      def uses_translations(options={})
        begin
          translated_class = eval("Translated" + self.to_s)
          has_many :translations, :class_name => translated_class.to_s, :foreign_key => options[:foreign_key]
          default_scope :include => :translations
          const_set(:USES_TRANSLATIONS, true)
          const_set(:TRANSLATION_CLASS, translated_class)
          attr_accessor :current_translation_language

          # creating attributes for the translated fields
          # also creating a method Class.attribute(language_iso_code)
          # which will return that attribute in the given language
          if defined?(translated_class) && translated_class.table_exists?
            translated_class.column_names.each do |a|
              # the two columns that the translation will always have which shouldn't override the main class
              unless a == 'id' || a == 'language_id'
                # if there is already an attribute with the same name as the translate attribute,
                # then none of thise will happen
                unless column_names.include?(a)
                  attr_accessor "translated_#{a}".to_sym

                  # creating a method with the name of the translated attribute. For example
                  # if we translated label, we're making
                  # def label(language_iso)
                  define_method(a.to_sym) do |*args|
                    # this is a funny way to check for the Language model existing. defined? would fail
                    # unless there was some reference to Language earlier in the application instance, thus
                    # the additional check for the model, which will load the model definition
                    language_exists = defined?(Language) || Language rescue nil
                    return nil unless language_exists

                    language_iso = args[0] || I18n.locale.to_s || APPLICATION_DEFAULT_LANGUAGE_ISO || nil
                    unless self.current_translation_language && language_iso == self.current_translation_language.iso_code
                      l = Language.from_iso(language_iso)
                      return nil if l.nil?
                      # load the translated fields as attributes of the current model
                      return nil unless set_translation_language(l)
                    end

                    return eval("translated_#{a}")
                  end
                end
              end
            end
          end

          # this method will search translations of this model whose language matches the parameter,
          # and creates attributes of the model corresponding to the translated fields
          # def set_translation_language(language_iso)
          define_method(:set_translation_language) do |language|
            return nil if language.class != Language
            return true if language == self.current_translation_language
            match = translations.select{|t| t.language_id == language.id }

            # no translation in this language to fallback to the default language
            if match.empty?
              if language.iso_639_1 != APPLICATION_DEFAULT_LANGUAGE_ISO
                return set_translation_language(Language.from_iso(APPLICATION_DEFAULT_LANGUAGE_ISO))
              else
                return nil
              end
            end

            # populate the translated attributes
            self.current_translation_language = language
            match[0].attributes.each do |a, v|
              # puts "SETTING #{self.class.class_name} #{a} to #{v}"
              eval("self.translated_#{a} = v") unless a == 'id' || a == 'language_id'
            end
          end

          # def self.find_by_translated(field, value, language_iso, :include => {})
          self.class.send(:define_method, :find_by_translated) do |field, value, *args|
            begin
              if args[0] && args[0].class == String && args[0].match(/^[a-z]{2}$/)
                options_language_iso = args[0]
              end
              options_hash = args.select{ |a| a && a.class == Hash && !a.blank? }.shift
              options_include = options_hash[:include] unless options_hash.blank?
              find_all = options_hash[:find_all] unless options_hash.blank?
              search_language_iso = options_language_iso || APPLICATION_DEFAULT_LANGUAGE_ISO || nil
              language_id = Language.id_from_iso(search_language_iso)
              return nil if language_id.nil?

              table = self::TRANSLATION_CLASS.table_name
              # find the record where the translated field is * and language is *
              found = send("find", ((find_all === true) ? :all : :first), :joins => :translations,
                :conditions => "`#{table}`.`#{field}` = '#{value}' AND `#{table}`.`language_id` = #{language_id}",
                :include => options_include)
            rescue => e
              # Language may not be defined yet
              puts e.message
              pp e.backtrace
            end
          end

          # def self.cached_find_translated(field, value, language_iso, :include => {})
          self.class.send(:define_method, :cached_find_translated) do |field, value, *args|
            if args[0] && args[0].class == String && args[0].match(/^[a-z]{2}$/)
              options_language_iso = args[0]
            end
            options_hash = args.select{ |a| a && a.class == Hash && !a.blank? }.shift
            find_all = options_hash[:find_all] unless options_hash.blank?
            language_iso = options_language_iso || APPLICATION_DEFAULT_LANGUAGE_ISO || nil
            cache_key = "#{field}/#{value}/#{language_iso}"
            cache_key += "/all" if find_all === true
            cached_with_local_cache(cache_key) do
              find_by_translated(field, value, language_iso, options_hash)
            end
          end

        rescue => e
          puts e.message
          pp e.backtrace
        end
      end  # end uses_translations

    end
  end
end

if $ENABLE_TRANSLATION_LOGS
  module I18n
    def self.translate_with_logging(*args)
      Logging::TranslationLog.inc(args[0])
      I18n.translate_without_logging(*args)
    end
    class << self
      alias_method_chain :translate, :logging
      alias :t :translate
    end
  end
end
