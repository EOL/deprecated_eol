class RefIdentifierType < ActiveRecord::Base

  has_many :ref_identifiers

  include NamedDefaults
  set_defaults :label, %w{url doi}

end
