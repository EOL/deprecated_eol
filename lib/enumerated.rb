# Creates a set of named and numbered defaults for a ActiveRecord::Base class, which is aware of translations, if any.
#
# This provides three conveniences:
#   • a (well-cached) set of methods to call each of these named defaults, and
#   • a #create_enumerated method which will (safely) ensure everything it expects to find is actually in the DB. See below.
#   • a #enumerations method which allows you to get the full list of known defaults.
#
# To use, include Enumerated in your class, then call the class method #enumerated, which takes the name of the field to
# populate, plus an array of what it's populated with.
#
#   enumerated :label, %w(Trusted Untrusted Unknown)
#
# ...in this case, you will get methods named #trusted, #untrusted, and #unknown pointing to instances with those labels. The
# #create_enumerated method will also automatically create those instances. #enumerations will return { :trusted => 'Trusted',
#
# names (as symbols). If you need to specify aliases for the values, pass a hash in place of the string:
#
#   enumerated :name, [{create_action: 'Create'}, 'Add', 'Another Action']
#
# ...in this case, you will get methods named #create_action, #add, and #another_action pointing to instances with those names. The
# #create_enumerated method will also automatically create those instances. #enumerations will return the array [:create_action,
# :create, :add].
#
# If your instances require additional fields specified when created, you should override the #create_enumerated method, and call
# #enumeration_creator with a hash. The keys of the hash MUST be the symbols returned by #enumerations, plus an additional key
# :defaults. For (a contrived) example:
#
#   def self.create_enumerated
#     enumeration_creator(
#       create_action: { group: 2, action_type: ActionType.fun },
#       add: { group: 2 },
#       another_action: { action_type: ActionType.other },
#       defaults: { group: 1, action_type: ActionType.normal }
#     )
#   end
#
# For example, in this case, #add will now be created with an #action_type of ActionType.normal (because it's in the defaults).
#
module Enumerated

  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods

    # This is the method you call on the class (a'la Rails relationships) to set the defaults and create the associated methods.
    def enumerated(field, defaults)
      @enum_field = field
      @enum_defaults = defaults
      @enum_translated = const_defined?(:USES_TRANSLATIONS)
      @enum_translated_class = Kernel.const_get("Translated#{self.name}") if @enum_translated
      @enum_foreign_key = self.name.foreign_key if @enum_translated
      @enum_methods_created = false
      add_enumerated_methods
      add_create_enumerated_method
    end

    # Allows us to detect when a class uses Enumerated (handy for specs):
    def enumerated?
      true
    end

    def enumerations
      return @enumerations if @enumerations
      @enumerations = {}
      @enum_defaults.each do |enum|
        if enum.is_a?(Hash)
          raise "You MUST only have one key in an enum definition hash" if enum.keys.count > 1
          @enumerations[enumeration_xform(enum.keys.first).to_sym] = enum.values.first
        else
          @enumerations[enumeration_xform(enum).to_sym] = enum
        end
      end
      @enumerations
    end

    def enumeration_xform(string)
      string.to_s.parameterize.underscore
    end

    # This is required during testing; we have to clear all these values out once tables are truncated:
    # TODO - this should also clear the Rails cache, using the cached_name_for method provided in core initializer.
    def clear_enumerated
      unless class_variables.empty? # Nothing to clear; avoids some trouble in migrations and early operations.
        enumerations.keys.each do |method_name|
          name = "@@#{method_name}".to_sym
          remove_class_variable(name) if class_variable_defined?(name)
        end
      end
    end

    # Creates the methods required to read the defaults.
    # If your defaults are a hash, the method name will use the value of the method_name key. If that's missing, it will use the
    # value of the enumerated field.
    # If your defaults are an array, it will use the name of the enumerated field.
    # The method name (unless you specified it in a hash) will be underscored (as one should expect).
    def add_enumerated_methods
      enumerations.each do |name, value|
        # ANNOYING: puts "** WARNING: named default method #{name} already exists, re-defined." if respond_to?(name)
        classvar = "@@#{name}".to_sym
        if @enum_translated && @enum_translated_class.send(:attribute_names).include?(@enum_field.to_s)
          define_singleton_method(name) do
            # NOTE - nothing is cached if it's nil...
            return class_variable_get(classvar) if class_variable_defined?(classvar) && class_variable_get(classvar)
            class_variable_set(classvar, cached_find_translated(@enum_field, value))
          end
        else
          define_singleton_method(name) do
            # NOTE - nothing is cached if it's nil...
            return class_variable_get(classvar) if class_variable_defined?(classvar) && class_variable_get(classvar)
            class_variable_set(classvar, cached_find(@enum_field, value))
          end
        end
      end
      @enum_methods_created = true
    end

    def add_create_enumerated_method
      if @enum_translated && @enum_translated_class.attribute_names.include?(@enum_field.to_s)
        define_singleton_method(:create_enumerated) do
          enumerations.each do |name, value|
            field_class = attribute_names.include?(@enum_field.to_s) ? self : @enum_translated_class
            trans_params = { @enum_field => value, language_id: Language.english.id }
            unless field_class.send(:exists?, { @enum_field => value, language_id: Language.english.id } )
              # NOTE: Stupid hack. Our DB wasn't auto_inc'ing the id when you
              # just insert the default ID the way Rails does it natively.
              # STUPID! Has to be a problem with the DB, but no time to
              # investigate. Soooo, work around.
              id = maximum(:id) || 0
              connection.execute("INSERT INTO #{table_name} (id) VALUES (#{id + 1})")
              this = last # without workaround: this.create!
              trans_params.merge!(@enum_foreign_key => this.id)
              trans = @enum_translated_class.send(:create!, trans_params)
            end
          end
        end
      else
        define_singleton_method(:create_enumerated) do
          enumerations.values.each do |value|
            params = { @enum_field => value }
            create!(params) unless exists?(@enum_field => value)
          end
        end
      end
    end

    def enumeration_creator(hash)
      #DEBUG: puts "++ #enumeration_creator"
      defaults = hash.has_key?(:defaults) ? hash.delete(:defaults) : {}
      #DEBUG: puts "++ Defaults:"
      #DEBUG: pp defaults
      autoinc_field = hash.delete(:autoinc)
      if @enum_translated
        enumerations.each_with_index do |(default, value), index|
          #DEBUG: puts "++ #{default} -> #{value}"
          params = defaults.dup
          params.merge!(hash[default]) if hash[default]
          #DEBUG: puts "++ #{default} -> #{value}"
          params[autoinc_field] = index + 1 if autoinc_field
          params.merge!(@enum_field => value) # Doing this last 'cause it *needs* to be the value...
          exist_params = { @enum_field => value, language_id: Language.english.id }
          field_class = attribute_names.include?(@enum_field.to_s) ? self : @enum_translated_class
          unless field_class.send(:exists?,
                                  exist_params.select { |k,v| field_class.send(:attribute_names).include?(k.to_s) } )
            #DEBUG: pp params.select { |k,v| field_class.send(:attribute_names).include?(k.to_s) }
            this = create!(params.select { |k,v| attribute_names.include?(k.to_s) } )
            trans_params = params.reverse_merge!(language_id: Language.english.id, @enum_foreign_key => this.id)
            #DEBUG: pp trans_params.select { |k,v| @enum_translated_class.send(:attribute_names).include?(k.to_s) }
            trans = @enum_translated_class.send(:create!,
              trans_params.select { |k,v| @enum_translated_class.send(:attribute_names).include?(k.to_s) } )
          end
        end
      else
        enumerations.each_with_index do |(default, value), index|
          params = defaults.merge(hash[default]).merge(@enum_field => value)
          params[autoinc_field] = index + 1 if autoinc_field
          create!(params) unless exists?(@enum_field => value)
        end
      end
    end

  end

end
