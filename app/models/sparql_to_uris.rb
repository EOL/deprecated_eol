class SparqlToUris
  attr_reader :uris
  def initialize(data)
    @uris = # TODO
  end
  def find(string)
    @uri.find { |uri| uri.uri == string }
  end
end
