class Mysql::MassInsert
  class << self # Everything is a class method on this one.
    # This is kinda crazy, but it takes an array of hashes and builds a single
    # insert statement.
    def from_hashes(hashes, model)
      keys = learn_keys(hashes)
      model.connection.execute(
        "INSERT INTO `#{model.table_name}` (`#{keys.to_a.join("`,`")}`)"\
        "  VALUES #{values_as_sql_sets(hashes, keys).join(", ")}"
      )
    end

    def learn_keys(hashes)
      keys = Set.new
      hashes.each do |hash|
        keys += hash.keys.sort
      end
      keys
    end

    def values_as_sql_sets(hashes, keys)
      inserts = []
      hashes.each do |hash|
        array = keys.map do |k|
          ActiveRecord::Base.connection.quote(hash[k])
        end
        inserts << "(#{ array.join(',') })"
      end
      inserts
    end
  end
end
