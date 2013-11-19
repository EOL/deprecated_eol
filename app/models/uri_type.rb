class UriType < ActiveRecord::Base

  uses_translations

  has_many :known_uris

  KNOWN_TYPES = [ 'measurement', 'association', 'value', 'metadata' ]

  include Enumerated
  enumerated :name, [ 'measurement', 'association', 'value', 'metadata', 'Unit of Measure' ]

  def self.create_defaults
    KNOWN_TYPES.each do |name|
      unless TranslatedUriType.exists?(:language_id => Language.default.id, :name => name)
        type = UriType.create
        TranslatedUriType.create(:name => name, :uri_type => type, :language => Language.default)
      end
    end
  end

end
