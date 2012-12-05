# EOL: the change here is to change all the ORs to a single IN condition if we can
module CompositePrimaryKeys
  module Predicates
    def cpk_or_predicate(predicates, table = nil)
      engine = figure_engine(table)
      table_name = nil
      table_field = nil
      table_and_fields_the_same = true
      table_ids = []
      predicates = predicates.map do |predicate|
        predicate_sql = engine ? predicate.to_sql(engine) : predicate.to_sql
        if table_and_fields_the_same && m = predicate_sql.match(/^`(.*?)`\.`(.*)` = ([0-9]*)$/)
          this_table_name = m[1]
          this_table_field = m[2]
          table_name ||= this_table_name
          table_field ||= this_table_field
          if (table_name != this_table_name) || (table_field != this_table_field)
            table_and_fields_the_same = false
          else
            table_ids << m[3]
          end
        else
          table_and_fields_the_same = false
        end
        "(#{predicate_sql})"
      end
      if table_and_fields_the_same && table_ids.length > 1
        predicates = "(`#{table_name}`.`#{table_field}` IN (#{table_ids.join(',')}))"
      else
        predicates = "(#{predicates.join(" OR ")})"
      end
      Arel::Nodes::SqlLiteral.new(predicates)
    end
  end
end