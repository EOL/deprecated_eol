# Mock-ish model to implement interface for KnownUri, when it's ... not.
class UnknownUri
  attr_reader :name, :uri
  def initialize(uri, options = {})
    @uri = uri
    @name = EOL::Sparql.uri_to_readable_label(uri) || uri.to_s
    EOL.log("WARNING: Unknown URI (#{uri})", prefix: "!") unless
      options[:literal]
  end

  def anchor
    @uri.to_s.gsub(/[^A-Za-z0-9]/, '_')
  end

  def definition
    "Not a known URI"
  end

  def position
    65000
  end

  def toc_items
    [EmptyTocItem.new]
  end

  def treat_as_string?
    false
  end
end
