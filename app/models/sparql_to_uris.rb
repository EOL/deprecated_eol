# Keys from input data (all values are either an RDF::URI or a literal):
#
# { :attribute, :value, :life_stage, :sex, :data_point_uri, :graph,
# :taxon_concept_id }
class SparqlToUris
  attr_reader :uris

  # TODO: NOTE! We can't handle associations. You MUST define those beforehand
  # yourself. ...I think that's reasonable, since there are a limited number of
  # them and the PHP code also needs to be aware of them.
  def initialize(data)
    @measurements = data.map { |hash| hash[:attribute].to_s }
    @values = data.flat_map do |hash|
      [ hash[:value].to_s if hash[:value].is_a?(RDF::URI),
        hash[:life_stage].to_s if hash[:value].is_a?(RDF::URI),
        hash[:sex].to_s if hash[:value].is_a?(RDF::URI)
      ]
    end.compact
    @uris = find_or_build_uris
  end

  private

  def find_or_build_uris
    @uris = KnownUri.where(uri: @measurements + @values)
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
