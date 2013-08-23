class UriType < ActiveRecord::Base

  uses_translations

  has_many :known_uris

  KNOWN_TYPES = ['measurement', 'association', 'measurement value', 'unit of measure']

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
      define_method(type) { cached_find_translated(:name, type) }
    end
  end

end
