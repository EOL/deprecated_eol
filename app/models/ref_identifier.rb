class RefIdentifier < ActiveRecord::Base

  self.primary_keys = :ref_id, :ref_identifier_type_id

  belongs_to :ref
  belongs_to :ref_identifier_type

  has_and_belongs_to_many :hierarchy_entries

  # A method that takes the identifier attribute, cleans it up, and adds the protocol (if it's missing).
  # This only works for DOI and URL identifiers.  We return the identifier as-is if we don't know the type.
  def link_to_identifier
    tmp_identifier = self.identifier
    if self.url?
      tmp_identifier = "http://#{tmp_identifier}" unless tmp_identifier =~ /http/i
    elsif self.doi?
      tmp_identifier.sub!(/^.*(10\.\d+\/\S*).*$/, "http://dx.doi.org/\\1")
    end
    return tmp_identifier
  end

  def display?
    return (self.url? or self.doi?)
  end

  def url?
    return self.ref_identifier_type.label =~ /url/i 
  end

  def doi?
    return self.ref_identifier_type.label =~ /doi/i
  end

end
