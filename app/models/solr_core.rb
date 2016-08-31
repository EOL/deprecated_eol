# encoding: utf-8
class SolrCore
  # Note the \s captures a lot of weird things (\v for example); the space
  # itself is fine (and that's what we replace it with), so "BAD" is a misnomer,
  # here.
  BAD_CHARS_REGEX = /[;×\"'|\s\x00-\x1F]+/
  CLEAN_TEXT_REGEX = /^[\w \(\),\.&-]+$/

  class << self
    def date(date)
      # "setting the default to 1969-12-31T07:00:01Z"
      date = 1 if ! date || date == 'NULL'
      date = Time.at(date) if date.is_a?(Integer)
      date.to_time.utc.iso8601
    end

    def string(text)
      return nil if text.nil?
      text = text.to_s # Sometimes we get Fixnums, etc.
      return nil if text == 'NULL' # Can come from DB
      return text if text.is_numeric?
      return text.gsub(/\s+/, " ") if text =~ CLEAN_TEXT_REGEX
      return I18n.transliterate(text) if text.is_utf8?
      text.gsub(BAD_CHARS_REGEX, " ").gsub(/\s+/, " ").strip
    end
  end
end
