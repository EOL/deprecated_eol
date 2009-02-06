module ActiveRecord::Comments::MysqlAdapter

  def self.included base
    base.extend ClassMethods
  end

  module ClassMethods

    # MySQL implementation of ActiveRecord::Comments::BaseExt#comment
    def mysql_comment table
      table_options = create_table_sql(table).split("\n").last
      if table_options =~ /COMMENT='/
        /COMMENT='(.*)'/.match(table_options).captures.first
      else
        nil
      end
    end

    # MySQL implementation of ActiveRecord::Comments::BaseExt#column_comment
    def mysql_column_comment column, table
      column_creation_sql = create_column_sql(column, table)
      if column_creation_sql =~ /COMMENT '/
        /COMMENT '(.*)'/.match(column_creation_sql).captures.first
      else
        nil
      end
    end

    private

    # Returns the SQL used to create the given table
    #
    # ==== Parameters
    # table<~to_s>::
    #   The name of the table to get the 'CREATE TABLE' SQL for
    #
    # ==== Returns
    # String:: the SQL used to create the table
    #
    # :api: private
    def create_table_sql table = table_name
      connection.execute("show create table `#{ table }`").all_hashes.first['Create Table']
    end

    # Returns the SQL used to create the given column for the given table
    #
    # ==== Parameters
    # column<~to_s>::
    #   The name of the column to get the creation SQL for
    #
    # table<~to_s>::
    #   The name of the table to get the 'CREATE TABLE' SQL for
    #
    # ==== Returns
    # String:: the SQL used to create the column
    #
    # :api: private
    def create_column_sql column, table = table_name
      full_table_create_sql = create_table_sql(table)
      parts = full_table_create_sql.split("\n")
      create_table = parts.shift # take off the first CREATE TABLE part
      create_table_options = parts.pop # take off the last options for the table, leaving just the columns
      sql_for_this_column = parts.find {|str| str =~ /^ *`#{ column }`/ }
      sql_for_this_column.strip! if sql_for_this_column
      sql_for_this_column
    end

  end

end

ActiveRecord::Base.send :include, ActiveRecord::Comments::MysqlAdapter

################ WE SHOULD DO EVERYTHING ON THE CONNECTION (ADAPTER) INSTEAD!!!!!!

module ActiveRecord::Comments::MysqlAdapterAdapter

  # MySQL implementation of ActiveRecord::Comments::BaseExt#comment
  def mysql_comment table
    table_options = create_table_sql(table).split("\n").last
    if table_options =~ /COMMENT='/
      /COMMENT='(.*)'/.match(table_options).captures.first
    else
      nil
    end
  end

  # MySQL implementation of ActiveRecord::Comments::BaseExt#column_comment
  def mysql_column_comment column, table
    column_creation_sql = create_column_sql(column, table)
    if column_creation_sql =~ /COMMENT '/
      /COMMENT '(.*)'/.match(column_creation_sql).captures.first
    else
      nil
    end
  end

  private

  # Returns the SQL used to create the given table
  #
  # ==== Parameters
  # table<~to_s>::
  #   The name of the table to get the 'CREATE TABLE' SQL for
  #
  # ==== Returns
  # String:: the SQL used to create the table
  #
  # :api: private
  def create_table_sql table = table_name
    execute("show create table `#{ table }`").all_hashes.first['Create Table']
  end

  # Returns the SQL used to create the given column for the given table
  #
  # ==== Parameters
  # column<~to_s>::
  #   The name of the column to get the creation SQL for
  #
  # table<~to_s>::
  #   The name of the table to get the 'CREATE TABLE' SQL for
  #
  # ==== Returns
  # String:: the SQL used to create the column
  #
  # :api: private
  def create_column_sql column, table = table_name
    full_table_create_sql = create_table_sql(table)
    parts = full_table_create_sql.split("\n")
    create_table = parts.shift # take off the first CREATE TABLE part
    create_table_options = parts.pop # take off the last options for the table, leaving just the columns
    sql_for_this_column = parts.find {|str| str =~ /^ *`#{ column }`/ }
    sql_for_this_column.strip! if sql_for_this_column
    sql_for_this_column
  end

end

ActiveRecord::ConnectionAdapters::AbstractAdapter.send :include, ActiveRecord::Comments::MysqlAdapterAdapter
