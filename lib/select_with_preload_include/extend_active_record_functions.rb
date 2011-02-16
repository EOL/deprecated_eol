# Various methods needed to deal with :select with :include options for .find

module ActiveRecord
  class Base
    class << self
      private
        # Given a find on a model with a :select option, add to the :select statement any fields needed
        # to finalize preload_associations and associate the records with their source records
        def add_association_keys_to_select(options)
          return options[:select] unless options[:include]
          select_table_fields = split_table_fields(options[:select])
          select_table_fields.concat add_association_keys_to_select_sub(self, options)
          reform_select_from_fields(select_table_fields.uniq)
        end
        
        # Given a find on a model with a :select option, add to the :select statement any fields needed
        # to finalize preload_associations and associate the records with their source records
        def add_association_keys_to_select_sub(klass, options)
          select_table_fields = class_primary_key_fields(klass)
          
          if options[:include].class == Symbol || options[:include].class == String
            select_table_fields.concat association_keys_for(klass, options[:include].to_sym)
          elsif options[:include].class == Array
            options[:include].each do |s|
              if s.class == Hash  # {:user => :favorites} or {:user => {:favorites => [:books, :movies]}}
                select_table_fields.concat association_keys_for(klass, s.keys[0].to_sym)
                
                # this :include has a nested :include, so continue recursively
                if r = klass.reflections[s.keys[0].to_sym]
                  nested_add_options = options.dup
                  nested_add_options[:include] = s.values[0]
                  select_table_fields.concat add_association_keys_to_select_sub(r.klass, nested_add_options)
                end
              elsif s.class == Symbol || s.class ==  String
                select_table_fields.concat association_keys_for(klass, s.to_sym)
              end
            end
          elsif options[:include].class == Hash
            select_table_fields.concat association_keys_for(klass, options[:include].keys[0].to_sym)
            
            # this :include has a nested :include, so continue recursively
            if r = klass.reflections[options[:include].keys[0].to_sym]
              nested_add_options = options.dup
              nested_add_options[:include] = options[:include].values[0]
              select_table_fields.concat add_association_keys_to_select_sub(r.klass, nested_add_options)
            end
          end
          
          select_table_fields.uniq
        end
        
        # Given a class and an association (reflection), add the appropriate primary or foreign keys to the array
        # of fields that must be returned for the association records to be attached to their source classes
        def association_keys_for(klass, association_name)
          select_table_fields = []
          
          # make sure there is a reflection with this name
          if r = klass.reflections[association_name]
            if r.macro == :belongs_to
              # A :belongs_to B => [a, r.primary_key], [b, b.primary_key]
              select_table_fields << [klass.table_name, r.primary_key_name.to_s]
              select_table_fields.concat(class_primary_key_fields(r.klass))
            elsif r.macro == :has_one
              # A :has_one B => [b, r.primary_key]
              select_table_fields << [r.klass.table_name, r.primary_key_name.to_s]
            elsif r.macro == :has_many
              if r.options[:through] && r.source_reflection
                # A :has_many B, :through C => [b, b.primary_key]
                select_table_fields.concat(class_primary_key_fields(r.source_reflection.klass))
              else
                # A :has_many B => [b, r.primary_key]
                select_table_fields << [r.klass.table_name, r.primary_key_name.to_s]
              end
            elsif r.macro == :has_and_belongs_to_many
              # A :has_and_belongs_to_many B => [b, b.primary_key]
              select_table_fields.concat(class_primary_key_fields(r.klass))
            end
          end
          select_table_fields
        end
        
        # return an array of a class's primary key fields
        # eg: [[table, id]]
        # or  [[table, id1], [table, id2]]
        def class_primary_key_fields(klass)
          fields = []
          if klass.primary_key.class == Array || klass.primary_key.class == CompositePrimaryKeys::CompositeKeys
            klass.primary_key.each do |pk|
              fields << [klass.table_name, pk.to_s]
            end
          else
            fields << [klass.table_name, klass.primary_key]
          end
          fields
        end
        
        # EOL: used to grab only the select fields that to pertain to this table
        # given:   User.find(:select => "name, `terms`.`definition`, friends.*)
        # returns: [['users', 'name'], ['terms', 'definition'], ['friends', '*']]
        def split_table_fields(select_statement, split_options = {})
          return select_statement if select_statement.class != String
          table_fields = []
          select_statement.split(",").each do |tf|
            # this will make:
            #   m[0] => 'table_name'
            #   m[1] => 'field_name'
            #   m[2] => ' as as_field_name'
            #   m[3] => 'count'
            if m = tf.strip.match(/^`?(\w+|\*)`?\.`?(\w+|\*)`?($| as \w+$)/)
              table_fields << [m[1], m[2], m[3]]
            elsif m = tf.strip.match(/^(\w+|\*)$/)
              # there was no table specified so default to current table
              table_fields << [self.table_name, m[1]]
            elsif m = tf.strip.match(/^(count)\((\w+|\*)\)($| as \w+$)/)  #count(*)
              # there was no table specified so default to current table
              table_fields << [self.table_name, m[2], m[3], m[1]]
            end
          end
          
          # delete those not for this table
          if split_options[:delete_other_model_selects]
            # delete every not for this table OR if we're in a has_and_belongs_to_many join, t0
            table_fields.delete_if {|tf| tf[0] != self.table_name && !(split_options[:is_join] && tf[0] == 't0')}
          end
          table_fields
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
        
        # EOL: used to turn select statements into strings. :select might be
        #   a string: "url, users.name, books.*, ..."
        #   a hash: {:users => :name, :books => "*", :movies => [:title, :director, :length]}
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
    end
  end
end