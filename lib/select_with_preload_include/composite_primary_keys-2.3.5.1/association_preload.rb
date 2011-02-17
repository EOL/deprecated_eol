# CompositePrimaryKeys also extends preload_belongs_to_association. The only change
# here is to make allow preload_options[:select] to take precedence

module CompositePrimaryKeys
  module ActiveRecord
    module AssociationPreload
      module ClassMethods
        def preload_belongs_to_association(records, reflection, preload_options={})
          options = reflection.options
          primary_key_name = reflection.primary_key_name.to_s.split(CompositePrimaryKeys::ID_SEP)

          if options[:polymorphic]
            raise AssociationNotSupported, "Polymorphic joins not supported for composite keys"
          else
            # I need to keep the original ids for each record (as opposed to the stringified) so
            # that they get properly converted for each db so the id_map ends up looking like:
            #
            # { '1,2' => {:id => [1,2], :records => [...records...]}}
            id_map = {}

            records.each do |record|
              key = primary_key_name.map{|k| record.send(k)}
              key_as_string = key.join(CompositePrimaryKeys::ID_SEP)

              if key_as_string
                mapped_records = (id_map[key_as_string] ||= {:id => key, :records => []})
                mapped_records[:records] << record
              end
            end


            klasses_and_ids = [[reflection.klass.name, id_map]]
          end

          klasses_and_ids.each do |klass_and_id|
            klass_name, id_map = *klass_and_id
            klass = klass_name.constantize
            table_name = klass.quoted_table_name
            connection = reflection.active_record.connection

            if composite?
              primary_key = klass.primary_key.to_s.split(CompositePrimaryKeys::ID_SEP)
              ids = id_map.keys.uniq.map {|id| id_map[id][:id]}

              where = (primary_key * ids.size).in_groups_of(primary_key.size).map do |keys|
                 "(" + keys.map{|key| "#{table_name}.#{connection.quote_column_name(key)} = ?"}.join(" AND ") + ")"
              end.join(" OR ")

              conditions = [where, ids].flatten
            else
              conditions = ["#{table_name}.#{connection.quote_column_name(primary_key)} IN (?)", id_map.keys.uniq]
            end

            conditions.first << append_conditions(reflection, preload_options)
            
            # EOL: this only change in this method is the inclusion of preload_options[:select] below
            associated_records = klass.find(:all,
              :conditions => conditions,
              :include    => options[:include],
              :select     => preload_options[:select] || options[:select],
              :joins      => options[:joins],
              :order      => options[:order])

            set_association_single_records(id_map, reflection.name, associated_records, primary_key)
          end
        end
      end
    end
  end
end