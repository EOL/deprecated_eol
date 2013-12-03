class UriType < ActiveRecord::Base

  uses_translations

  has_many :known_uris

  KNOWN_TYPES = [ 'measurement', 'association', 'value', 'metadata' ]

  include Enumerated
  enumerated :name, [ 'measurement', 'association', 'value', 'metadata', 'Unit of Measure' ]

end
