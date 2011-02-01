# This library file declares extensions to the Core classes, as well as some of the "Core" Rails classes
# (ActiveRecord and what-not).

# There is a problem with $CACHE returning frozen objects.  The following two patches should fix it:
#
# https://rails.lighthouseapp.com/projects/8994/tickets/2860
# https://rails.lighthouseapp.com/projects/8994/tickets/2859
#
# Discussion about the problem:
# https://rails.lighthouseapp.com/projects/8994/tickets/2655-railscache-freezes-all-objects-passed-to-it

module ActiveReload
  class MasterDatabase < ActiveRecord::Base
    # This makes the MasterDatabase work as expected in the test and dev environments.
  end
end

module ActiveRecord
  class Base
    def dup
      obj = super
      obj.instance_variable_set('@attributes', instance_variable_get('@attributes').dup)
      obj
    end
  end
end

module ActiveSupport
  module Cache
    class MemoryStore < Store
      def write(name, value, options = nil)
        super
        # ORIGINAL: @data[name] = value.freeze
        # NEW:
        @data[name] = (value.duplicable? ? value.dup : value).freeze
      end
    end
  end
  
  class TimeWithZone
    def mysql_timestamp
      # 2010-12-31 03:50:09
      return strftime("%Y-%m-%d %H:%M:%S")
    end
    def solr_timestamp
      # 2010-12-31T03:50:09Z
      return strftime("%Y-%m-%dT%H:%M:%SZ")
    end
  end
end

class Time
  def mysql_timestamp
    # 2010-12-31 03:50:09
    return strftime("%Y-%m-%d %H:%M:%S")
  end
  def solr_timestamp
    # 2010-12-31T03:50:09Z
    return strftime("%Y-%m-%dT%H:%M:%SZ")
  end
end



# This is a fix for EOLINFRASTRUCTURE-1606 ... NewRelic appears to be calling [] on a Nil somewhere, and this avoids the
# problem.
class NilClass
  def [](a,b=nil)
    return '[DATA MISSING]'
  end
end

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


  # Note that I change strong to b, 'cause strong appears to be overridden in our CSS.  Hrmph.
  def allow_some_html
    # inline RegEx passed to gsub calls leak memory! We declare them first:
    @allowed_attributes_in_allow_some_html = /\s*\/|\s+href=['"][^'"]+['"]/ 
    start_tag   = /</
    end_tag     = />/
    line_breaks = /\r\n/
    text = self.gsub(start_tag, '&lt;')
    text.gsub!(end_tag, '&gt;')
    ['a', 'b', 'blockquote', 'br', 'em', 'i', 'p', 'small', 'strong', 'cite'].each do |tag|
      tag_regex = /&lt;(\/)?#{tag}(#{@allowed_attributes_in_allow_some_html})?\s*&gt;/i
      text.gsub!(tag_regex, "<\\1#{tag.gsub(/strong/, 'b')}\\2>")
    end
    return text.gsub(line_breaks, '<br/>')
  end

  def firstcap
    @firstcap_regex = /^(<[^>]*>)?(['"])?([^ ]+)( |$)/
    self.gsub(@firstcap_regex) { $1.to_s + $2.to_s + $3.capitalize + $4 }
  end
  
  def firstcap!
    @firstcap_regex = /^(<[^>]*>)?(['"])?([^ ]+)( |$)/
    self.gsub!(@firstcap_regex) { $1.to_s + $2.to_s + $3.capitalize + $4 }
  end
  
  
  #  old list from gem:
  # [ 'a', 'b', 'blockquote', 'br', 'caption', 'cite', 'code', 'col', 'colgroup', 'dd', 'dl', 'dt', 'em', 'embed', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'i', 'img', 'li', 'ol', 'p', 'pre', 'q', 'small', 'strike', 'strong', 'sub', 'sup', 'table', 'tbody', 'td', 'tfoot', 'th', 'thead', 'tr', 'u', 'ul' ],
  # more full list:
  def appropriate_html_tags
    ['address', 'applet', 'area', 'a', 'base', 'basefont', 'big', 'blockquote', 'br', 'b', 'caption', 'center', 'cite', 'code', 'dd', 'dfn', 'dir', 'div', 'dl', 'dt', 'em', 'embed', 'font', 'form', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'hr', 'img', 'input', 'isindex', 'i', 'kbd', 'link', 'li', 'map', 'menu', 'meta', 'ol', 'option', 'param', 'pre', 'p', 'samp', 'script', 'select', 'small', 'span', 'strike', 'strong', 'style', 'sub', 'sup', 'table', 'td', 'textarea', 'th', 'title', 'tr', 'tt', 'ul', 'u', 'var', 'legend', 'fieldset']
  end
      
  def sanitize_html
    text = self
    
    eol_relaxed = {
      :elements => appropriate_html_tags,

    #width, height and postion removed to prevent hardcoding in provider's HTML
      :attributes => {
        'a'          => ['class', 'href', 'rel', 'style', 'target', 'title'],
        'blockquote' => ['cite'],
        'cite'       => ['id', 'style'],
        'col'        => ['span', 'width'],
        'colgroup'   => ['span', 'width'],
        'div'        => ['id', 'class', 'style'],
        'embed'      => ['id', 'type', 'src', 'flashvars'],
        'img'        => ['align', 'alt', 'src', 'title', 'rel'],
        'li'         => ['class', 'id'],
        'ol'         => ['class', 'id', 'start', 'type'],
        'q'          => ['cite'],
        'script'     => ['type'],
        'style'      => ['align', 'alt', 'background', 'border', 'color', 'dir', 'font', 'font-family', 'font-size', 'font-style', 'font-weight', 'lang', 'line-height', 'margin', 'margin-left', 'margin-right', 'margin-top', 'media', 'padding', 'src', 'text-align', 'text-decoration', 'text-indent', 'title', 'type'],
        'span'       => ['class', 'id', 'style', 'title'],
        'sub'        => ['class', 'id', 'title', 'style'],
        'sup'        => ['class', 'id', 'title', 'style'],
        'table'      => ['summary', 'width', 'cellspacing', 'class', 'id', 'title', 'style'],
        'td'         => ['abbr', 'axis', 'colspan', 'rowspan', 'width', 'class', 'title', 'style'],
        'tr'         => ['style'],
        'th'         => ['abbr', 'axis', 'class', 'colspan', 'rowspan', 'scope', 'style',
                         'width'],
        'ul'         => ['type'],
        'fieldset'   => ['class', 'rel'],
        'legend'     => ['class']
      },
      
      :protocols => {
        'a'          => {'href' => ['ftp', 'http', 'https', 'mailto', 'javascript', :relative]},
        'blockquote' => {'cite' => ['http', 'https', :relative]},
        'embed'      => {'src' => ['http', 'https', :relative]},
        'img'        => {'src'  => ['http', 'https', :relative]},
        'q'          => {'cite' => ['http', 'https', :relative]}
      }
    }
    
    Sanitize.clean(text, eol_relaxed)
    
  end

  def truncate(length)
    if self.length >= length
      self[0..length-1] + "..."
    else
      self
    end
  end
  
  def remove_diacritics
    self.mb_chars.normalize(:kd).gsub(/[^\x00-\x7F]/n,'').to_s
  end
  
  def word_count
    split(/ /).length
  end
  
  def is_numeric?
    begin
      Float(self)
    rescue
      false # not numeric
    else
      true # numeric
    end
  end
  
  def is_int?
    begin
      Integer(self)
    rescue
      false # not numeric
    else
      true # numeric
    end
  end

  def cleanup_for_presentation
    self.gsub(/[_]{20,}/, ' ')
  end
  
end

class Array

  # some methods on Hash return an Array like [ [key,value], [key,value] ] instead 
  # of returning a Hash.  this turns an Array of that style back into a Hash.
  def hashify
    inject({}) do |all,this|
      all[this.first] = this.last
      all 
    end
  end
  
  # expects an array of Hashes
  # [ {'id' => 1 , 'label' => first},
  #   {'id' => 2 , 'label' => first}]
  # will create a new array where $attribute is unique by taking the first instance and deleting the rest
  # mimics some of what the MySQL GROUP BY does
  def group_hashes_by!(attribute)
    used_values = []
    hashes_to_delete = []
    self.each_with_index do |h, index|
      hashes_to_delete << h if used_values.include?(h[attribute])
      used_values << h[attribute]
    end
    for h in hashes_to_delete
      self.delete(h)
    end
  end
  
  # expects an array of objects
  # will create a new array where $attribute is unique by taking the first instance and deleting the rest
  # mimics some of what the MySQL GROUP BY does
  def group_objects_by!(attribute)
    used_values = []
    objects_to_delete = []
    self.each_with_index do |obj, index|
      value = obj.send(attribute.to_sym)
      objects_to_delete << obj if used_values.include?(value)
      used_values << value
    end
    for obj in objects_to_delete
      self.delete(obj)
    end
  end

end

class Hash

  # does the same as Array#hashify.
  #
  # assumes an Array like [ [key,value], [key,value] ]
  def self.from_array array
    array.hashify
  end

end

class ActiveRecord::Migration
  def self.not_okay_in_production
    # Perhaps not the right error class to throw, but I'm not aware of good alternatives:
    raise ActiveRecord::IrreversibleMigration.new("It is not okay to run this migration on a production database.") if
      $PRODUCTION_MODE
  end
end


# I need this to sanitize SQL into strings:
class << ActiveRecord::Base
  public :sanitize_sql_array
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

      def cached(key, options = {}, &block)
        name = cached_name_for(key)
        if $CACHE # Sometimes during tests, cache has not yet been initialized.
          wrote_cache_key(name)
          $CACHE.fetch(name) do
            yield
          end
        else
          yield
        end
      end

      # Store a list of all of the keys we create for this model (using these cache methods)... speeds up clearing.
      def wrote_cache_key(key)
        name = cached_name_for('cached_names')
        keys = $CACHE.read(name) || []
        return keys if keys.include? key
        keys = keys + [key] # Can't use << or += here because Cache has frozen the array.
        $CACHE.write(name, keys)
      end

      def clear_all_caches
        keys = $CACHE.read(cached_name_for('cached_names')) || []
        keys.each do |key|
          $CACHE.delete(key)
        end
        $CACHE.write(TODO, keys)
      end

      def cached_name_for(key)
        "#{RAILS_ENV}/#{self.table_name}/#{key.underscore_non_word_chars}"[0..249]
      end

      # returns the full table name of this ActiveRecord::Base, 
      # including the database name.
      #
      #   >> User.full_table_name
      #   => "eol_development.users"
      #
      def full_table_name
        database_name + '.' + table_name
      end

      # returns a hash of configuration variables for this ActiveRecord::Base's connection adapter
      def database_config
        # in production, we have a ConnectionProxy with many adapters 
        # otherwise #connection directly returns the adapter
        adapter = self.connection.instance_eval { @current } || self.connection
        adapter.instance_eval { @config }
      end
      
      # returns the name of the database for this ActiveRecord::Base
      def database_name
        @database_name ||= self.connection.execute('select database()').fetch_row[0]
      end
      
      def reload
        self.with_master do
          super
        end
      end

    end
    
    def self.with_master(&block)
      if self.connection.respond_to? 'with_master'
        self.connection.set_to_master!
        something = yield
        self.connection.set_to_slave!
        something
      else
        yield
      end
    end
  end
  
  module ConnectionAdapters
    class MysqlAdapter
      def config
        return @config
      end
      
      def command_line_parameters
        mysql_params = "--host='#{@config[:host]}' --user='#{@config[:username]}' --password='#{@config[:password]}'"
        mysql_params += " --port='#{@config[:port]}'" unless @config[:port].blank?
        mysql_params += " --default-character-set='#{@config[:encoding]}'" unless @config[:encoding].blank?
        return mysql_params
      end
    end
  end
end


class Float
  def round_to(x)
    (self * 10**x).round.to_f / 10**x
  end

  def ceil_to(x)
    (self * 10**x).ceil.to_f / 10**x
  end

  def floor_to(x)
    (self * 10**x).floor.to_f / 10**x
  end
end
