class DataValue

  attr_reader :uri, :label, :definition

  def initialize(known_uri_or_string)
    if known_uri_or_string.is_a?(KnownUri)
      @uri = known_uri_or_string.uri
      @label = known_uri_or_string.name
      @definition = known_uri_or_string.definition
    elsif label = EOL::Sparql.uri_to_readable_label(known_uri_or_string)
      @uri = known_uri_or_string
      @label = label
    else
      @uri = known_uri_or_string
      @label = known_uri_or_string
    end
  end

  # Looks like a hash...
  def [](key)
    # handle the keys that we're used to
    case key
    when :uri
      uri
    when :label
      label
    when :definition
      definition
    else
      nil
    end
  end

  # Smells like a hash...
  def has_key?(key)
    case key
    when :uri
      ! uri.blank?
    when :label
      ! label.blank?
    when :definition
      ! definition.blank?
    else
      false
    end
  end
    

  def to_s
    @label # TODO... something better
  end

end
