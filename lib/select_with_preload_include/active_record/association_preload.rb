# The extensions here allow for :select options to be passed along to all associations
# so when saying Model.find(:last, :select => 'z.*', :include => {:a, :b, :z})
# the select z.* statment gets applied to the Z.find call

module ActiveRecord
  module AssociationPreload
    module ClassMethods
      protected
        # EOL: the only change to this method is to pass preload_options to child associations
        def preload_associations(records, associations, preload_options={})
          records = [records].flatten.compact.uniq
          return if records.empty?
          case associations
          when Array then associations.each {|association| preload_associations(records, association, preload_options)}
          when Symbol, String then preload_one_association(records, associations.to_sym, preload_options)
          when Hash then
            associations.each do |parent, child|
              raise "parent must be an association name" unless parent.is_a?(String) || parent.is_a?(Symbol)
              preload_associations(records, parent, preload_options)
              reflection = reflections[parent]
              parents = records.map {|record| record.send(reflection.name)}.flatten.compact
              unless parents.empty?
                parents.first.class.preload_associations(parents, child, preload_options)
              end
            end
          end
        end

      private
        def preload_has_and_belongs_to_many_association(records, reflection, preload_options={})
          table_name = reflection.klass.quoted_table_name
          id_to_record_map, ids = construct_id_map(records)
          records.each {|record| record.send(reflection.name).loaded}
          options = reflection.options

          conditions = "t0.#{reflection.primary_key_name} #{in_or_equals_for_ids(ids)}"
          conditions << append_conditions(reflection, preload_options)
          
          # EOL: the only change in this method is passing along preload_options[:select]
          associated_records = reflection.klass.with_exclusive_scope do
            reflection.klass.find(:all, :conditions => [conditions, ids],
              :include => options[:include],
              :joins => "INNER JOIN #{connection.quote_table_name options[:join_table]} t0 ON #{reflection.klass.quoted_table_name}.#{reflection.klass.primary_key} = t0.#{reflection.association_foreign_key}",
              :select => "#{preload_options[:select] || options[:select] || table_name+'.*'}, t0.#{reflection.primary_key_name} as the_parent_record_id",
              :order => options[:order])
          end
          set_association_collection_records(id_to_record_map, reflection.name, associated_records, 'the_parent_record_id')
        end
        
        def preload_has_one_association(records, reflection, preload_options={})
          return if records.first.send("loaded_#{reflection.name}?")
          id_to_record_map, ids = construct_id_map(records, reflection.options[:primary_key])
          # EOL: duplicating the options
          options = reflection.options.dup
          records.each {|record| record.send("set_#{reflection.name}_target", nil)}
          if options[:through]
            through_records = preload_through_records(records, reflection, options[:through], {:select => preload_options[:select]})
            through_reflection = reflections[options[:through]]
            through_primary_key = through_reflection.primary_key_name
            unless through_records.empty?
              source = reflection.source_reflection.name
              through_records.first.class.preload_associations(through_records, source)
              if through_reflection.macro == :belongs_to
                rev_id_to_record_map, rev_ids = construct_id_map(records, through_primary_key)
                rev_primary_key = through_reflection.klass.primary_key
                through_records.each do |through_record|
                  add_preloaded_record_to_collection(rev_id_to_record_map[through_record[rev_primary_key].to_s],
                                                     reflection.name, through_record.send(source))
                end
              else
                through_records.each do |through_record|
                  add_preloaded_record_to_collection(id_to_record_map[through_record[through_primary_key].to_s],
                                                     reflection.name, through_record.send(source))
                end
              end
            end
          else
            set_association_single_records(id_to_record_map, reflection.name, find_associated_records(ids, reflection, preload_options), reflection.primary_key_name)
          end
        end
        
        def preload_has_many_association(records, reflection, preload_options={})
          return if records.first.send(reflection.name).loaded?
          # EOL: duplicating the options
          options = reflection.options.dup

          primary_key_name = reflection.through_reflection_primary_key_name
          id_to_record_map, ids = construct_id_map(records, primary_key_name || reflection.options[:primary_key])
          records.each {|record| record.send(reflection.name).loaded}

          if options[:through]
            through_records = preload_through_records(records, reflection, options[:through], {:select => preload_options[:select]})
            through_reflection = reflections[options[:through]]
            unless through_records.empty?
              source = reflection.source_reflection.name
              options[:select] = preload_options[:select]
              through_records.first.class.preload_associations(through_records, source, options)
              through_records.each do |through_record|
                through_record_id = through_record[reflection.through_reflection_primary_key].to_s
                add_preloaded_records_to_collection(id_to_record_map[through_record_id], reflection.name, through_record.send(source))
              end
            end

          else
            set_association_collection_records(id_to_record_map, reflection.name, find_associated_records(ids, reflection, preload_options),
                                               reflection.primary_key_name)
          end
        end
        
        def preload_through_records(records, reflection, through_association, preload_options={})
          through_reflection = reflections[through_association]
          through_primary_key = through_reflection.primary_key_name

          if reflection.options[:source_type]
            interface = reflection.source_reflection.options[:foreign_type]
            # EOL: extending preload options so we can use the :select passed on through
            preload_options[:conditions] = ["#{connection.quote_column_name interface} = ?", reflection.options[:source_type]]
            records.compact!
            records.first.class.preload_associations(records, through_association, preload_options)

            # Dont cache the association - we would only be caching a subset
            through_records = []
            records.each do |record|
              proxy = record.send(through_association)

              if proxy.respond_to?(:target)
                through_records << proxy.target
                proxy.reset
              else # this is a has_one :through reflection
                through_records << proxy if proxy
              end
            end
            through_records.flatten!
          else
            # EOL: passing on the preload_options including :select options
            records.first.class.preload_associations(records, through_association, preload_options)
            through_records = records.map {|record| record.send(through_association)}.flatten
          end
          through_records.compact!
          through_records
        end
        
        def preload_belongs_to_association(records, reflection, preload_options={})
          return if records.first.send("loaded_#{reflection.name}?")
          # EOL: duplicating the options
          options = reflection.options.dup
          primary_key_name = reflection.primary_key_name
  
          if options[:polymorphic]
            polymorph_type = options[:foreign_type]
            klasses_and_ids = {}
  
            # Construct a mapping from klass to a list of ids to load and a mapping of those ids back to their parent_records
            records.each do |record|
              if klass = record.send(polymorph_type)
                klass_id = record.send(primary_key_name)
                if klass_id
                  id_map = klasses_and_ids[klass] ||= {}
                  id_list_for_klass_id = (id_map[klass_id.to_s] ||= [])
                  id_list_for_klass_id << record
                end
              end
            end
            klasses_and_ids = klasses_and_ids.to_a
          else
            id_map = {}
            records.each do |record|
              key = record.send(primary_key_name)
              if key
                mapped_records = (id_map[key.to_s] ||= [])
                mapped_records << record
              end
            end
            klasses_and_ids = [[reflection.klass.name, id_map]]
          end
          
          klasses_and_ids.each do |klass_and_id|
            klass_name, id_map = *klass_and_id
            next if id_map.empty?
            klass = klass_name.constantize
            
            table_name = klass.quoted_table_name
            primary_key = reflection.options[:primary_key] || klass.primary_key
            column_type = klass.columns.detect{|c| c.name == primary_key}.type
            ids = id_map.keys.map do |id|
              if column_type == :integer
                id.to_i
              elsif column_type == :float
                id.to_f
              else
                id
              end
            end
            conditions = "#{table_name}.#{connection.quote_column_name(primary_key)} #{in_or_equals_for_ids(ids)}"
            conditions << append_conditions(reflection, preload_options)
            associated_records = klass.with_exclusive_scope do
              # EOL: the only change is to allow preload_options[:select] to take precedence
              klass.find(:all, :conditions => [conditions, ids],
                                            :include => options[:include],
                                            :select => preload_options[:select] || options[:select],
                                            :joins => options[:joins],
                                            :order => options[:order])
            end
            set_association_single_records(id_map, reflection.name, associated_records, primary_key)
          end
        end
    end
  end
end