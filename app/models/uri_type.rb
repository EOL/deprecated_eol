class UriType < ActiveRecord::Base

  uses_translations

  has_many :known_uris

  include EnumDefaults

  set_defaults :name,
   [ 'measurement', 'association', 'value', 'metadata' ]

end
