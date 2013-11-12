module EnumDefaults

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
      @enum_translated = options[:translated] # TODO - we could detect this pretty easily.
      @enum_translated_class = Kernel.const_get("Translated#{self.name}") if @enum_translated
      @enum_foreign_key = self.name.foreign_key
      default_methods(options)
      add_default_values_method
      add_create_defaults_method
    end

    # Allows for a class method to get the defaults.
    def add_default_values_method
      define_singleton_method(:default_values) do
        @enum_defaults
      end
    end

    # Creates the methods required to read the defaults.
    # If your defaults are a hash, the method name will use the value of the method_name key. If that's missing, it will use the
    # value of the enumerated field.
    # If your defaults are an array, it will use the name of the enumerated field.
    # The method name (unless you specified it in a hash) will be underscored (as one should expect).
    def default_methods(options = {})
      @enum_defaults.each do |default|
        value = default.is_a?(Hash) ? default[@enum_field] : default
        name = default.is_a?(Hash) ?
          default[:method_name] || default[@enum_field].to_s.gsub(/\s+/, '_').underscore :
          default.to_s.gsub(/\s+/, '_').underscore
        puts "++ creating #{name} method"
        if @enum_translated
          define_singleton_method(name) do
            return class_variable_get("@@#{name}".to_sym) if class_variable_defined?("@@#{name}".to_sym)
            class_variable_set("@@#{name}".to_sym, cached_find_translated(@enum_field, value))
          end
        else
          define_singleton_method(name) do
            return class_variable_get("@@#{name}".to_sym) if class_variable_defined?("@@#{name}".to_sym)
            class_variable_set("@@#{name}".to_sym, cached_find(@enum_field, value))
          end
        end
      end
    end

    def add_create_defaults_method
      if @enum_translated
        define_singleton_method(:create_defaults) do
          @enum_defaults.each_with_index do |default, order|
            params = @enum_default_params
            params = default.is_a?(Hash) ? params.merge(default) : params.merge(@enum_field => default)
            params.delete(:method_name)
            params.delete(@enum_field) # Because that goes on the *translated* model...
            if @enum_autoinc_field
              params[@enum_autoinc_field] = order + 1
            end
            # NOTE - Really, we should check enum_default_translated_params for a language_id, in case they want something
            # specific... but that's never pragmatically a problem, so I'm not implementing that here.
            value = default.is_a?(Hash) ? default[@enum_field] : default
            puts "++ exists? #{@enum_field} => #{value}, language => #{Language.default.id}"
            unless @enum_translated_class.send(:exists?, @enum_field => value, language_id: Language.default.id)
              this = create(params)
              trans = @enum_translated_class.send(:create,
                        @enum_default_translated_params.merge(
                          language_id: Language.default.id,
                          @enum_foreign_key => this.id,
                          @enum_field => value
                        )
              )
            end
          end
        end
      else
        define_singleton_method(:create_defaults) do
          @enum_defaults.each_with_index do |default, order|
            params = @enum_default_params
            params = default.is_a?(Hash) ? params.merge(default) : params.merge(@enum_field => default)
            params.delete(:method_name)
            if @enum_autoinc_field
              params[@enum_autoinc_field] = order + 1
            end
            value = default.is_a?(Hash) ? default[@enum_field] : default
            puts "++ #{@enum_field} exists? -> #{value} = #{exists?(@enum_field => value)}"
            puts "params:"
            pp params
            create(params) unless exists?(@enum_field => value)
          end
        end
      end
    end

  end

end
