# Base is extended to send along the :select option to preload_associations
# construct_finder_sql is extended to
#   - add any select fields that are needed for associations (primary or foreign keys)
#   - remove any fields for *this* query which do not reference this model's table

module ActiveRecord
  class Base
    class << self
      private
        def find_every(options)
          include_associations = merge_includes(scope(:find, :include), options[:include])
          
          if include_associations.any? && references_eager_loaded_tables?(options)
            records = find_with_associations(options)
          else
            records = find_by_sql(construct_finder_sql(options))
            if include_associations.any?
              # EOL: the only change in this method is to send along the select option
              preload_associations(records, include_associations, {:select => options[:select]})
            end
          end
          
          records.each { |record| record.readonly! } if options[:readonly]
          
          records
        end
        
        def construct_finder_sql(options)
          scope = scope(:find)
          
          # EOL: this block was added
          #   only use selects that pertain to this table
          options[:select] = select_statement_to_string(options[:select])
          modified_select = options[:select]
          if options[:select] && (!options[:joins] || options[:joins].match(/INNER JOIN `(\w*)` t0 ON /))
            # add in needed select fields. Associations will require a foreign key or primary
            # key to be included - so add these even if they are not in the original :select statement
            options[:select] = add_association_keys_to_select(options)
            
            split_options = {:delete_other_model_selects => true}
            
            # this case is a select from a :has_and_belongs_to_many which creates an INNER JOIN
            # we'll need to keep the fields for this table AND the fields from the join table
            if options[:joins] && options[:joins].match(/INNER JOIN `(\w*)` t0 ON /)
              split_options[:is_join] = true 
            end
            
            # remove any fields not pertaining to this table
            select_table_fields = split_table_fields(options[:select], split_options)
            modified_select = reform_select_from_fields(select_table_fields.uniq)
          end
          
          #EOL: changed options[:select] to modified_select in the line below
          sql  = "SELECT #{modified_select || (scope && scope[:select]) || default_select(options[:joins] || (scope && scope[:joins]))} "
          sql << "FROM #{options[:from]  || (scope && scope[:from]) || quoted_table_name} "
        
          add_joins!(sql, options[:joins], scope)
          add_conditions!(sql, options[:conditions], scope)
        
          add_group!(sql, options[:group], options[:having], scope)
          add_order!(sql, options[:order], scope)
          add_limit!(sql, options, scope)
          add_lock!(sql, options, scope)
        
          sql
        end
    end
  end
end  