# This library file declares extensions to the Core classes, as well as some of the "Core" Rails classes
# (ActiveRecord and what-not).
class String

  # Note that I change strong to b, 'cause strong appears to be overridden in our CSS.  Hrmph.
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
    
  def sanitize_html
    text = self
    
    eol_relaxed = {
      :elements => 
      #  old list from gem:
      # [ 'a', 'b', 'blockquote', 'br', 'caption', 'cite', 'code', 'col', 'colgroup', 'dd', 'dl', 'dt', 'em', 'embed', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'i', 'img', 'li', 'ol', 'p', 'pre', 'q', 'small', 'strike', 'strong', 'sub', 'sup', 'table', 'tbody', 'td', 'tfoot', 'th', 'thead', 'tr', 'u', 'ul' ],
      # more full list:
      [
        'address', 'applet', 'area', 'a', 'base', 'basefont', 'big', 'blockquote', 'br', 'b', 'caption', 'center', 'cite', 'code', 'dd', 'dfn', 'dir', 'div', 'dl', 'dt', 'em', 'embed', 'font', 'form', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'hr', 'img', 'input', 'isindex', 'i', 'kbd', 'link', 'li', 'map', 'menu', 'meta', 'ol', 'option', 'param', 'pre', 'p', 'samp', 'script', 'select', 'small', 'span', 'strike', 'strong', 'style', 'sub', 'sup', 'table', 'td', 'textarea', 'th', 'title', 'tr', 'tt', 'ul', 'u', 'var'
        ],

      :attributes => {
        'a'          => ['class', 'href', 'rel', 'style', 'target', 'title'],
        'blockquote' => ['cite'],
        'col'        => ['span', 'width'],
        'colgroup'   => ['span', 'width'],
        'div'        => ['id', 'class', 'style'],
        'embed'      => ['id', 'type', 'src', 'flashvars'],
        'img'        => ['align', 'alt', 'src', 'title'],
        'ol'         => ['start', 'type'],
        'q'          => ['cite'],
        'style'      => ['align', 'alt', 'background', 'border', 'color', 'dir', 'font', 'font-family', 'font-size', 'font-style', 'font-weight', 'lang', 'line-height', 'margin', 'margin-left', 'margin-right', 'margin-top', 'media', 'padding', 'src', 'text-align', 'text-decoration', 'text-indent', 'title', 'type'],
        'span'       => ['class', 'id', 'style', 'title'],
        'sup'        => ['class', 'title', 'style'],
        'table'      => ['summary', 'width', 'cellspacing', 'class', 'title', 'style'],
        'td'         => ['abbr', 'axis', 'colspan', 'rowspan', 'width', 'class', 'title', 'style'],
        'tr'         => ['style'],
        'th'         => ['abbr', 'axis', 'class', 'colspan', 'rowspan', 'scope', 'style',
                         'width'],
        'ul'         => ['type']
      },
      
      :protocols => {
        'a'          => {'href' => ['ftp', 'http', 'https', 'mailto',
                                    :relative]},
        'blockquote' => {'cite' => ['http', 'https', :relative]},
        'embed'      => {'src' => ['http', 'https', :relative]},
        'img'        => {'src'  => ['http', 'https', :relative]},
        'q'          => {'cite' => ['http', 'https', :relative]}
      }
    }
    
    Sanitize.clean(text, eol_relaxed)
    
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

