# This library file declares extensions to the Core classes, as well as some of the "Core" Rails classes
# (ActiveRecord and what-not).
class String

  def allow_some_html
    # inline RegEx passed to gsub calls leak memory! We declare them first:
    @allowed_attributes_in_allow_some_html = /\s*\/|\s+href=['"][^'"]+['"]/ 
    start_tag   = /</
    end_tag     = />/
    line_breaks = /\r\n/
    text = self.gsub(start_tag, '&lt;')
    text.gsub!(end_tag, '&gt;')
    ['a', 'b', 'blockquote', 'br', 'em', 'i', 'p', 'small', 'strong'].each do |tag|
      tag_regex = /&lt;(\/)?#{tag}(#{@allowed_attributes_in_allow_some_html})?\s*&gt;/i
      text.gsub!(tag_regex, "<\\1#{tag.gsub(/strong/, 'b')}\\2>")
    end
    return text.gsub(line_breaks, '<br/>')
  end

  def firstcap
    @firstcap_regex = /^(<[^>]*>)?([^ ]+)( |$)/
    self.gsub(@firstcap_regex) { $1.to_s + $2.chars.capitalize + $3 }
  end

end

# I need this to sanitize SQL into strings:
class << ActiveRecord::Base
  public :sanitize_sql
end

class ActiveRecord::Migration
  def self.not_okay_in_production
    # Perhaps not the right error class to throw, but I'm not aware of good alternatives:
    raise ActiveRecord::IrreversibleMigration.new("It is not okay to run this migration on a production database.") if
      $PRODUCTION_MODE
  end
end

