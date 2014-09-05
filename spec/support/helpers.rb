module Helpers
  def populate_tables(table_names)
    table_names.each do |name|
      name.classify.constantize.send(:create_enumerated)
    end
  end
end
