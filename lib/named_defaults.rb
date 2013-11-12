# Creates a set of named and numbered defaults for a ActiveRecord::Base class, which is aware of translations, if any.
# 
# This provides three conveniences:
#   • a (well-cached) set of methods to call each of these named defaults, and
#   • a #create_defaults method which will (safely) ensure everything it expects to find is actually in the DB.
#   • a #default_values method which allows you to get the full list of known defaults.
#
# To use, include NamedDefaults in your class, then call the class method #set_defaults, which takes three arguments:
#   • the attribute which is "named and numbered", and
#   • a list of defaults - this may be a lambda, if you want it evaluated lazily (for example, if you are filling values with
#     class methods that may not exists at compile-time.
#   • a hash of options (see below)
#
# The list of defaults passed to #set_defaults can either be ai simple array or an array of hashes.
# If the array is simple, the values are understood to be populating the named attribute.
# If the array is a hash, each hash is resembles the parameters passed to a #create method, with one additional (optional) key
# called :method_name. :method_name is used to supply a unique name for the "named" method, if it's different from the value
# of the "named and numbered attribute." For example, you might have an attribute of "label" and you may want the label to be
# "an author", but you would like the method name to be :author, so you would use a hash of {label: 'an Author', method_name:
# :author}.
#
# Options that can be passed to #set_defaults:
#
#   autoinc_field - this will "number" the defaults (ie: to make them sortable) by populating the specified field with an
#                   incrementing integer. The first default will be '1', the second '2', and so on.
#   check_exists_by - occasionally your "named and numbered" field isn't necessarily unique. Use this argument to tell
#                     #set_defaults which attribute *is* unique. (Note that this attribute must then be specified for each
#                     hash in the defaults array.)
#   default_params - a hash of parameters which wll be passed to the created objects by default. This may be a Proc.
#   default_translated_params - a hash of parameters which wll be passed to the created *translated* objects by default. This
#                               may be a Proc.
module NamedDefaults

  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods

    # This is the method you call on the class (a'la Rails relationships) to set the defaults and create the associated methods.
    def set_defaults(field, defaults, options = {})
      @enum_field = field.to_sym
      @enum_defaults = defaults
      @enum_default_params = options[:default_params] || {}
      @enum_default_translated_params = options[:default_translated_params] || {}
      @enum_autoinc_field = options[:autoinc_field]
      @enum_check_exists_by = options[:check_exists_by]
      @enum_translated = const_defined?(:USES_TRANSLATIONS)
      @enum_translated_class = Kernel.const_get("Translated#{self.name}") if @enum_translated
      @enum_foreign_key = self.name.foreign_key
      default_methods
      add_create_defaults_method
    end

    # Allows us to detect when a class uses NamedDefaults (handy for specs):
    def is_enum?
      true
    end

    def default_values
      @enum_defaults.is_a?(Proc) ? @enum_defaults.call : @enum_defaults
    end

    # This is required during testing; we have to clear all these values out once tables are truncated:
    def clear_default_caches
      default_values.each do |default|
        name = "@@#{build_default_name(default)}".to_sym
        remove_class_variable(name) if class_variable_defined?(name)
      end
    end

    def build_default_name(default)
      default.is_a?(Hash) ?
        default[:method_name] || default[@enum_field].to_s.gsub(/\s+/, '_').underscore :
        default.to_s.gsub(/\s+/, '_').underscore
    end

    # Creates the methods required to read the defaults.
    # If your defaults are a hash, the method name will use the value of the method_name key. If that's missing, it will use the
    # value of the enumerated field.
    # If your defaults are an array, it will use the name of the enumerated field.
    # The method name (unless you specified it in a hash) will be underscored (as one should expect).
    def default_methods
      default_values.each do |default|
        value = default.is_a?(Hash) ? default[@enum_field] : default
        name = build_default_name(default)
        classvar = "@@#{name}".to_sym
        if @enum_translated && @enum_translated_class.send(:attribute_names).include?(@enum_field.to_s)
          define_singleton_method(name) do
            return class_variable_get(classvar) if class_variable_defined?(classvar) &&
              class_variable_get(classvar) # NOTE - nothing is cached if it's nil...
            class_variable_set(classvar, cached_find_translated(@enum_field, value))
          end
        else
          define_singleton_method(name) do
            return class_variable_get(classvar) if class_variable_defined?(classvar) &&
              class_variable_get(classvar) # NOTE - nothing is cached if it's nil...
            class_variable_set(classvar, cached_find(@enum_field, value))
          end
        end
      end
    end

    def add_create_defaults_method
      if @enum_translated
        define_singleton_method(:create_defaults) do
          default_values.each_with_index do |default, order|
            params = @enum_default_params.is_a?(Proc) ? @enum_default_params.call : @enum_default_params
            params = default.is_a?(Hash) ? params.merge(default) : params.merge(@enum_field => default)
            params.delete(:method_name)
            if @enum_autoinc_field
              params[@enum_autoinc_field] = order + 1
            end
            value = default.is_a?(Hash) ? default[@enum_field] : default
            exist_params = { @enum_field => value, language_id: Language.english.id }
            field_class = attribute_names.include?(@enum_field.to_s) ? self : @enum_translated_class
            unless field_class.send(:exists?,
                                    exist_params.select { |k,v| field_class.send(:attribute_names).include?(k.to_s) })
              this = create!(params.select { |k,v| attribute_names.include?(k.to_s) })
              trans_params = @enum_default_translated_params.is_a?(Proc) ?
                @enum_default_translated_params.call :
                @enum_default_translated_params.dup
              trans_params.reverse_merge!(language_id: Language.english.id, @enum_foreign_key => this.id)
              trans_params.merge!(params)
              trans = @enum_translated_class.send(:create!,
                trans_params.select { |k,v| @enum_translated_class.send(:attribute_names).include?(k.to_s) })
            end
          end
        end
      else
        define_singleton_method(:create_defaults) do
          default_values.each_with_index do |default, order|
            params = @enum_default_params.is_a?(Proc) ? @enum_default_params.call : @enum_default_params
            params = default.is_a?(Hash) ? params.merge(default) : params.merge(@enum_field => default)
            params.delete(:method_name)
            if @enum_autoinc_field
              params[@enum_autoinc_field] = order + 1
            end
            check_exists_by = @enum_check_exists_by || @enum_field
            value = default.is_a?(Hash) ? default[check_exists_by] : default
            create!(params) unless exists?(check_exists_by => value)
          end
        end
      end
    end

  end

end
