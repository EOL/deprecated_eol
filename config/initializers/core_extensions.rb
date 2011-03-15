$CACHE ||= Rails.cache

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
  
  def strip_italics
    self.gsub(/<\/?i>/i, "")
  end

  def underscore_non_word_chars
    @@non_word_chars_regex ||= /[^A-Za-z0-9\/]/
    @@dup_underscores_regex ||= /__+/
    string = self.clone
    string.gsub(@@non_word_chars_regex, '_').gsub(@@dup_underscores_regex, '_')
  end
end

module ActiveRecord
  class Base
    class << self

      # options is there so that we can pass in the :serialize => true option in the cases where we were using Yaml...
      # I am going to try NOT doing anything with that option right now, to see if it works.  If not, however, I want to at
      # least have it passed in when we needed it, so the code can change later if needed.
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
        $CACHE.read(name)
      end
      
      def cached(key, options = {}, &block)
        name = cached_name_for(key)
        if $CACHE # Sometimes during tests, cache has not yet been initialized.
          $CACHE.fetch(name) do
            yield
          end
        else
          yield
        end
      end
      
      def cached_name_for(key)
        "#{RAILS_ENV}/#{self.table_name}/#{key.underscore_non_word_chars}"[0..249]
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
                  
                  define_method(a.to_sym) do |*args|
                    # this is a funny way to check for the Language model existing. defined? would fail
                    # unless there was some reference to Language earlier in the application instance, thus
                    # the additional check for the model, which will load the model definition
                    language_exists = defined?(Language) || Language rescue nil
                    return nil unless language_exists
                    
                    language_iso = args[0] || APPLICATION_DEFAULT_LANGUAGE_ISO || nil
                    unless self.current_translation_language && language_iso == self.current_translation_language.iso_639_1
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
          define_method(:set_translation_language) do |language|
            # language_iso = args[0] || APPLICATION_DEFAULT_LANGUAGE_ISO || nil
            # return if language_iso == self.current_translation_language
            # language_id = Language.id_from_iso(language_iso)
            # return nil if language_id.nil?
            return nil if language.class != Language
            return true if language == self.current_translation_language
            match = translations.select{|t| t.language_id == language.id }
            return nil if match.empty?  # no translation in this language
            
            # populate the translated attributes
            self.current_translation_language = language
            match[0].attributes.each do |a, v|
              # puts "SETTING #{self.class.class_name} #{a} to #{v}"
              eval("self.translated_#{a} = v") unless a == 'id' || a == 'language_id' 
            end
          end
          
          self.class.send(:define_method, :find_by_translated) do |field, value, *args|
            begin
              if args[0] && args[0].class == String && args[0].match(/^[a-z]{2}$/)
                options_language_iso = args[0]
              end
              options_include = args.select{ |a| a && a.class == Hash && !a[:include].blank? }.shift
              options_include = options_include[:include] unless options_include.blank?
              language_iso = options_language_iso || APPLICATION_DEFAULT_LANGUAGE_ISO || nil
              language_id = Language.id_from_iso(language_iso)
              return nil if language_id.nil?
              
              table = self::TRANSLATION_CLASS.table_name
              # find the record where the translated field is * and language is *
              found = send("find", :first, :joins => :translations,
                :conditions => "`#{table}`.`#{field}` = '#{value}' AND `#{table}`.`language_id` = #{language_id}",
                :include => options_include)
              
              # if the default language wasn't chosen, swtich translated attributes to new language
              if found
                found.set_translation_language(language_iso) if language_iso != APPLICATION_DEFAULT_LANGUAGE_ISO
              end
              found
            rescue => e
              # Language may not be defined yet
              puts e.message
              pp e.backtrace
            end
          end
          
          self.class.send(:define_method, :cached_find_translated) do |field, value, *args|
            if args[0] && args[0].class == String && args[0].match(/^[a-z]{2}$/)
              options_language_iso = args[0]
            end
            options_include = args.select{ |a| a && a.class == Hash && !a[:include].blank? }.shift
            language_iso = options_language_iso || APPLICATION_DEFAULT_LANGUAGE_ISO || nil
            cached("#{field}/#{value}/#{language_iso}") do
              find_by_translated(field, value, language_iso, options_include)
            end
          end
          
        rescue => e
          puts e.message
          pp e.backtrace
        end
      end
    end
  end
end
