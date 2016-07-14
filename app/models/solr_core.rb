# encoding: utf-8
class SolrCore
  BAD_CHARS_REGEX = /[;×\"'|\n\r\t ]+/
  CLEAN_TEXT_REGEX = /^[a-zA-Z0-9 \(\),\.&-_]+$/

  def self.date(date)
    # "setting the default to 1969-12-31T07:00:01Z"
    date = 1 if ! date || date == 'NULL'
    date = Time.at(date) if date.is_a?(Integer)
    date.to_time.utc.iso8601
  end

  def self.string(text)
    return nil if text.nil?
    text = text.to_s # Sometimes we get Fixnums, etc.
    return nil if text == 'NULL' # Can come from DB
    return text if text.is_numeric?
    return text.gsub(/\s+/, " ") if text =~ CLEAN_TEXT_REGEX
    return I18n.transliterate(text) if text.is_utf8?
    text.gsub(BAD_CHARS_REGEX, " ").gsub(/\s+/, " ").strip
  end
end
