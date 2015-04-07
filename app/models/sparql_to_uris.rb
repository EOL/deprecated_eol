class SparqlToUris
  attr_reader :uris

  def initialize(data)
    @data = data
    add_measurements
    add_values
    @uris = find_or_build_uris
  end

  private

  def add_measurements
    @measurements = Set.new
    @data.each do |hash|
      @measurements << grab(hash, :attribute)
      @measurements << grab(hash, :inverse_attribute)
    end
    @measurements.delete(nil)
  end

  def add_values
    @values = Set.new
    @data.each do |hash|
      @values << grab(hash, :life_stage),
      @values << grab(hash, :sex),
      @values << grab(hash, :statistical_method),
      @values << grab(hash, :unit_of_measure_uri),
      @values << grab(hash, :value) unless # it's an association, in which case:
        hash.has_key?(:target_taxon_concept_id)
    end
    @values.delete(nil)
  end

  def grab(hash, key)
    if hash[key].is_a?(RDF::URI)
      hash[key].to_s
    else
      nil
    end
  end

  def find_or_build_uris
    @uris = KnownUri.where(uri: (@measurements + @values).to_a)
    hashes = prepare_attributes(@measurements, :measurement)
    hashes += prepare_attributes(@values, :value)
    build_uris
    build_new_translated_names
  end

  def build_uris
    Mysql::MassInsert.from_hashes(hashes)
    @new_uris = KnownUri.where(uri: @measurements + @values)
    @uris += new_uris
  end

  def build_new_translated_names
    language_id = Language.default.id
    translations = @new_uris.map do |uri|
      { known_uri_id: uri.id,
        # TODO: Better if we could handle number at the end of the name:
        name: uri.split('/').last.underscore.humanize,
        language_id: language_id
      }
    end
  end

  # NOTE: setting the position here isn't _actually_ trustworthy; it would be
  # better if you re-built the positions after inserting everything. If someone
  # adds a KnownUri while this is "thinking," there will be a duplicate.
  # ...That's not likely to happen, so I am not going to muddy the code to
  # account for it.
  def prepare_attributes(uris, type)
    # Remove any we already know about:
    uris.delete_if { |uri| @uris.find { |kuri| kuri.uri == uri } }
    last_position = KnownUri.maximum(:position) || 0
    uris.map do |uri|
      {
        uri: uri,
        vetted_id: Vetted.unknown.id,
        visibility_id: Visibility.visible.id,
        exclude_from_exemplars: true,
        position: last_position += 1,
        uri_type_id: UriType.call(type).id,
        hide_from_glossary: true
      }
    end
  end

  def find(string)
    @uri.find { |uri| uri.uri == string }
  end
end
