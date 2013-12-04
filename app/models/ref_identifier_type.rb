class RefIdentifierType < ActiveRecord::Base

  has_many :ref_identifiers

  include Enumerated
  enumerated :label, %w(url doi)

end
