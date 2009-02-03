module ActiveRecord::Comments::ColumnExt
  attr_reader :table_name

  def comment
    ActiveRecord::Base.column_comment name, table_name
  end
end
