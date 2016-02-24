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

  # Few languages can "safely" downcase. For example, in German, it's quite awkward to downcase nouns. So:
  def i18n_downcase
    @@safe_downcasing_locales = [:en, :es, :mk, :sr, :fr]
    return self unless defined?(I18n) && I18n.locale && @@safe_downcasing_locales.include?(I18n.locale.to_sym)
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

  # No, this is not a comprehensive list of languages where it's acceptable (and/or applicable) to capitalize all the
  # words in a common name, but this is our current whitelist. ...Likely to be updated...
  def capitalize_all_words_if_language_safe
    if [:de, :en, :es, :fr, :nl].include?(I18n.locale.to_sym)
      capitalize_all_words
    else
      debugger if Rails.env.test? && I18n.locale != :ko # Tests shouldn't get here (except one for :ko)
      self
    end
  end

  def capitalize_all_words
    string = self.clone
    unless string.blank?
      string = string.split(/ /).map do |w|
        ignores = String.words_not_to_capitalize[I18n.locale.to_sym]
        if(ignores && ignores.include?(w.downcase))
          w.downcase
        else
          w.firstcap
        end
      end.join(' ')
    end
    string
  end

  def self.words_not_to_capitalize
    { :en => [ 'and', 'of' ] }
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
        r = cached(key, options) do
          r = send("find_by_#{field}", value, :include => options[:include])
        end
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

      def cached(key, options = {}, &block)
        name = cached_name_for(key)
        if Rails.cache # Sometimes during tests, cache has not yet been initialized.
          if v = Rails.cache.read(name)
            return v
          else
            EOL.log("Cache miss: #{name}") if EOL.respond_to?(:log)
            Rails.cache.delete(name) if Rails.cache.exist?(name)
            Rails.cache.fetch(name) do
              data_to_cache = yield
              if data_to_cache.is_a?(ActiveRecord::Relation)
                data_to_cache = data_to_cache.all
              end
              data_to_cache
            end
          end
        else
          yield
        end
      end

      def cached_name_for(key)
        "#{Rails.env}/#{self.table_name}/#{key.underscore_non_word_chars}"[0..249]
      end
    end
  end
end
