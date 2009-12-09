# some helpful extensions

class Array

  # some methods on Hash return an Array like [ [key,value], [key,value] ] instead 
  # of returning a Hash.  this turns an Array of that style back into a Hash.
  def hashify
    inject({}) do |all,this|
      all[this.first] = this.last
      all 
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

class String
  # Normalize a string for better matching, e.g. for searches
  def normalize
    @@normalization_regex ||= /[;:,\.\(\)\[\]\!\?\*_\\\/\"\']/
    @@spaces_regex        ||= /\s+/
    name = self.clone
    return name.downcase.gsub(@@normalization_regex, '').gsub(@@spaces_regex, ' ')
  end
end

module ActiveRecord
  class Base
    class << self

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
        database_config[:database]
      end

    end
  end
end
