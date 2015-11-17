module Helpers
  def truncate_tables(*table_names)
    table_names.each do |name|
      connection = name.to_s.classify.constantize.send(:connection)
      EOL::Db.truncate_table(connection, name)
    end
  end

  def populate_tables(*table_names)
    table_names.each do |name|
      begin
        name.to_s.classify.constantize.send(:create_enumerated)
      rescue NoMethodError => e
        raise "#create_enumerated not defined for #{name.to_s.classify}"
      end
    end
  end
end
