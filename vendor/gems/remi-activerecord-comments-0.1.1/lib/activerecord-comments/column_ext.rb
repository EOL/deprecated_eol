module ActiveRecord::Comments::ColumnExt
  attr_reader :table_name

  def comment
    raise "table_name not set for column #{ self.inspect }" if table_name.nil? or table_name.empty?
    ActiveRecord::Base.column_comment name, table_name
  end
end
