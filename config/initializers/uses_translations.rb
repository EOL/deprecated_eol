module ActiveRecord
  class Base
    class << self
      def uses_translations(options={})
        begin
          translated_class = Kernel.const_get("Translated" + self.to_s)
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

                    return send("translated_#{a}")
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
              send("translated_#{a}=", v) unless a == 'id' || a == 'language_id'
            end
          end

          # def self.find_by_translated(field, value, language_iso, :include => {})
          self.class.send(:define_method, :find_by_translated) do |field, value, *args|
            begin
              if args[0] && args[0].class == String && args[0].match(/^[a-z]{2}$/)
                options_language_iso = args[0]
              end
              options_hash = args.select{ |a| a && a.class == Hash && !a.blank? }.shift
              options_include = options_hash ? Array(options_hash[:include]).compact : []
              options_include << :translations # NOTE - you would think the default include applies, but it doesn't appear to be. :|
              find_all = options_hash ? options_hash[:find_all] : false
              search_language_iso = options_language_iso || APPLICATION_DEFAULT_LANGUAGE_ISO || nil
              language_id = Language.id_from_iso(search_language_iso)
              return nil if language_id.nil?
              table = self::TRANSLATION_CLASS.table_name
              # find the record where the translated field is * and language is *
              found = find(find_all ? :all : :first, :joins => :translations,
                :conditions => "`#{table}`.`#{field}` = '#{value}' AND `#{table}`.`language_id` = #{language_id}",
                :include => options_include)
              return nil if found.blank?
              ids = found.is_a?(Array) ? found.map(&:id) : found.id
              found = where(id: ids).includes(options_include)
              return ids.is_a?(Array) ? found : found.first # Because the #where always returns an array...
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
            find_all = options_hash ? options_hash[:find_all] : false
            language_iso = options_language_iso || APPLICATION_DEFAULT_LANGUAGE_ISO || nil
            cache_key = "#{field}/#{value}/#{language_iso}"
            cache_key += "/all" if find_all
            cached(cache_key) do
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
