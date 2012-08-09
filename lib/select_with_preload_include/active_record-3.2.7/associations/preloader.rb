module ActiveRecord
  module Associations
    class Preloader
      # EOL: sending options to second preloader
      def preload_hash(association)
        association.each do |parent, child|
          Preloader.new(records, parent, options).run
          Preloader.new(records.map { |record| record.send(parent) }.flatten, child, options).run
        end
      end
      
      # EOL: added check of options
      def preload_one(association)
        grouped_records(association).each do |reflection, klasses|
          klasses.each do |klass, records|
            # accepting a special hash of select parameters
            new_options = options.dup
            if options[:select] && options[:select].class == Hash && options[:select][klass.table_name.to_sym]
              new_options[:select] = select_statement_to_string(options[:select][klass.table_name.to_sym])
            end
            preloader_for(reflection).new(klass, records, reflection, new_options).run
          end
        end
      end
      
      # # EOL: used to turn select statements into strings. :select might be
      # #   a string: "url, users.name, books.*, ..."
      # #   a hash: {:users => :name, :books => "*", :movies => [:title, :director, :length]}
      def select_statement_to_string(select)
        if select.class == Hash
          new_select_fields = []
          select.each do |table, fields|
            if fields.class == Array
              fields.each do |field|
                new_select_fields << [table.to_s, field.to_s]
              end
            else
              new_select_fields << [table.to_s, fields.to_s]
            end
          end
          return reform_select_from_fields(new_select_fields)
        end
        # its not a Hash, so return it
        select
      end
      
      # EOL: used to grab only the select fields that to pertain to this table
      # given:   [['users', 'name'], ['terms', 'definition', ' as term_d'], ['friends', '*']]
      # returns: `users`.`name`, `terms`.`definition` as term_d, `friends`.*
      def reform_select_from_fields(table_fields)
        # if we're asking for * then ignore all other individual fields
        table_fields.each do |tf|
          if tf[1] == '*'
            table_fields.delete_if {|k| k[0] == tf[0] && k[1] != '*'}
          end
        end
        
        # re-form the select with the remainder
        new_select_fields = []
        table_fields.each do |tf|
          new_tf = "`#{tf[0]}`."
          new_tf += (tf[1] == '*') ? "*" : "`#{tf[1]}`"
          
          # tf[2] is the fourth option, aggregate functions
          # eg: ['users', 'username', ' as login_name', 'count'] => count(`users`.`username`) as login_name
          new_tf = tf[3] + "(#{new_tf})" unless tf[3].blank?
          
          # tf[2] is the third option, as
          # eg: ['users', 'username', ' as login_name'] => `users`.`username` as login_name
          new_tf += tf[2] unless tf[2].blank?
          new_select_fields << new_tf
        end
        
        # return nil instead of empty array
        return nil if new_select_fields.blank?
        new_select_fields.join(",")
      end
    end
  end
end
