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
        cached("#{field}/#{value}", options) do
          send("find_by_#{field}", value)
        end
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
                attr_accessor "translated_#{a}".to_sym unless column_names.include?(a)
              
                define_method(a.to_sym) do |*args|
                  return nil unless defined?(Language)
                  language_iso = args[0] || current_translation_language || nil
                  if language_iso == current_translation_language
                    return eval("translated_#{a}")
                  end
                  language_id = Language.id_from_iso(language_iso)
                  return nil if language_id.nil?
                  if translations
                    match = translations.select{|t| t.language_id == language_id }
                    return nil if match.empty?
                    return match[0][a]
                  end
                end
              end
            end
          end
          
          define_method(:after_initialize) do
            # Language was causing a recusvie loop because of the language lookup in the next method
            set_translation_language
          end
          
          define_method(:set_translation_language) do |*args|
            language_iso = args[0] || APPLICATION_DEFAULT_LANGUAGE_ISO || nil
            language_id = Language.id_from_iso(language_iso)
            return nil if language_id.nil?
            self.current_translation_language = language_iso
            match = translations.select{|t| t.language_id == language_id }
            unless match.empty?
              # populate the translated attributes
              match[0].attributes.each do |a, v|
                # puts "SETTING #{self.class.class_name} #{a} to #{v}"
                eval("self.translated_#{a} = v") unless a == 'id' || a == 'language_id' 
              end
            end
          end
          
          self.class.send(:define_method, :find_by_translated) do |field, value, *args|
            begin
              language_iso = args[0] || APPLICATION_DEFAULT_LANGUAGE_ISO || nil
              language_id = Language.id_from_iso(language_iso)
              return nil if language_id.nil?
              
              table = self::TRANSLATION_CLASS.table_name
              # find the record where the translated field is * and language is *
              found = send("find", :first, :joins => :translations,
                :conditions => "`#{table}`.`#{field}` = '#{value}' AND `#{table}`.`language_id` = #{language_id}")
              
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
            language_iso = args[0] || APPLICATION_DEFAULT_LANGUAGE_ISO || nil
            cached("#{field}/#{value}/#{language_iso}") do
              find_by_translated(field, value, language_iso)
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
