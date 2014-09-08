module Helpers
  def populate_tables(*table_names)
    table_names.each do |name|
      name.to_s.classify.constantize.send(:create_enumerated)
    end
  end
end
