module EnumDefaults

  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def set_defaults(field, defaults, options = {})
      @enum_field = field.to_sym
      @enum_defaults = defaults
      @enum_default_params = options[:default_params] || {}
      @enum_default_translated_params = options[:default_translated_params] || {}
      @enum_translated = options[:translated]
      @enum_translated_class = Kernel.const_get("Translated#{self.name}") if @enum_translated
      @enum_foreign_key = self.name.foreign_key
      default_methods(options)
      add_create_defaults_method
    end

    # Creates the methods required to read the defaults...
    def default_methods(options = {})
      set = @enum_defaults.is_a?(Hash) ? @enum_defaults.keys : @enum_defaults
      set.each do |default|
        value = @enum_defaults.is_a?(Hash) ? @enum_defaults[default] : default
        value = value.gsub(/\s+/, '_').underscore
        name = default.to_s.gsub(/\s+/, '_').underscore
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
            if @enum_autoinc_field
              params[@enum_autoinc_field] = order + 1
            end
            this = create(params)
            trans = @enum_translated_class.send(:create, @enum_default_translated_params.merge(
              @enum_foreign_key: this.id,
              @enum_field => default
            ))
          end
        end
      else
        define_singleton_method(:create_defaults) do
          @enum_defaults.each_with_index do |default, order|
            params = @enum_default_params.merge(@enum_field => default)
            if @enum_autoinc_field
              params[@enum_autoinc_field] = order + 1
            end
            create(params)
          end
        end
      end
    end

  end

end
