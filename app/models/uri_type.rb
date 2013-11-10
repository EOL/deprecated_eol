class UriType < ActiveRecord::Base

  uses_translations

  has_many :known_uris

  include NamedDefaults

  set_defaults :name, [ 'measurement', 'association', 'value', 'metadata', 'unit of measure' ]

end
