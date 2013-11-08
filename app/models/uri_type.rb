class UriType < ActiveRecord::Base

  uses_translations

  has_many :known_uris

  KNOWN_TYPES = [ 'measurement', 'association', 'value', 'metadata', 'Unit of Measure' ]

  def self.create_defaults
    KNOWN_TYPES.each do |name|
      unless TranslatedUriType.exists?(:language_id => Language.default.id, :name => name)
        type = UriType.create
        TranslatedUriType.create(:name => name, :uri_type => type, :language => Language.default)
      end
    end
  end

  KNOWN_TYPES.each do |type|
    eigenclass = class << self; self; end
    eigenclass.class_eval do
      method_name = type.parameterize.underscore
      define_method(method_name) do
        return class_variable_get("@@#{method_name}".to_sym) if class_variable_defined?("@@#{method_name}".to_sym)
        class_variable_set("@@#{method_name}".to_sym, cached_find_translated(:name, type))
      end
    end
  end

end
