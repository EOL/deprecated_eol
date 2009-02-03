module ActiveRecord::Comments::BaseExt

  def self.included base
    base.extend ClassMethods

    base.instance_eval {
      class << self
        alias_method_chain :columns, :table_name # this is evil!!!  how to fix?  column needs to know its table  :(
      end
    }
  end

  module ClassMethods

    # Get the database comment (if any) defined for a table
    #
    # ==== Parameters
    # table<~to_s>::
    #   The name of the table to get the comment for, default is 
    #   the #table_name of the ActiveRecord::Base class this is 
    #   being called on, eg. +User.comment+
    #
    # ==== Returns
    # String:: The comment for the given table (or nil if no comment)
    #
    # :api: public
    def comment table = self.table_name
      adapter = connection.adapter_name.downcase
      database_specific_method_name = "#{ adapter }_comment"
      
      if self.respond_to? database_specific_method_name
        send database_specific_method_name, table.to_s
      else

        # try requiring 'activerecord-comments/[name-of-adapter]_adapter'
        begin

          # see if there right method exists after requiring
          require "activerecord-comments/#{ adapter }_adapter"
          if self.respond_to? database_specific_method_name
            send database_specific_method_name, table.to_s
          else
            raise ActiveRecord::Comments::UnsupportedDatabase.new("#{adapter} unsupported by ActiveRecord::Comments")
          end

        rescue LoadError
          raise ActiveRecord::Comments::UnsupportedDatabase.new("#{adapter} unsupported by ActiveRecord::Comments")
        end
      end
    end

    # Get the database comment (if any) defined for a column
    #
    # ==== Parameters
    # column<~to_s>::
    #   The name of the column to get the comment for
    #
    # table<~to_s>::
    #   The name of the table to get the column comment for, default is 
    #   the #table_name of the ActiveRecord::Base class this is 
    #   being called on, eg. +User.column_comment 'username'+
    #
    # ==== Returns
    # String:: The comment for the given column (or nil if no comment)
    #
    # :api: public
    def column_comment column, table = self.table_name
      adapter = connection.adapter_name.downcase
      database_specific_method_name = "#{ adapter }_column_comment"
      
      if self.respond_to? database_specific_method_name
        send database_specific_method_name, column.to_s, table.to_s
      else

        # try requiring 'activerecord-comments/[name-of-adapter]_adapter'
        begin

          # see if there right method exists after requiring
          require "activerecord-comments/#{ adapter }_adapter"
          if self.respond_to? database_specific_method_name
            send database_specific_method_name, column.to_s, table.to_s
          else
            raise ActiveRecord::Comments::UnsupportedDatabase.new("#{adapter} unsupported by ActiveRecord::Comments")
          end

        rescue LoadError
          raise ActiveRecord::Comments::UnsupportedDatabase.new("#{adapter} unsupported by ActiveRecord::Comments")
        end
      end
    end

    # Extends ActiveRecord::Base#columns, setting @table_name as an instance variable 
    # on each of the column instances that are returned
    #
    # ==== Returns
    # Array[ActiveRecord::ConnectionAdapters::Column]::
    #   Returns an Array of column objects, each with @table_name set
    #
    # :api: private
    def columns_with_table_name *args
      columns = columns_without_table_name *args
      table = self.table_name # make table_name available as variable in instanve_eval closure
      columns.each do |column|
        column.instance_eval { @table_name = table }
      end
      columns
    end

  end

end
