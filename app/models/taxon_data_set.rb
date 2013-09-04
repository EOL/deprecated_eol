# Basically, I made this quick little class because the sort method required in two places and it didn't belong in one or t'other.
class TaxonDataSet

  include Enumerable

  def initialize(rows, options = {})
    @virtuoso_results = rows
    @taxon_concept_id = options[:taxon_concept_id]
    @language = options[:language] || Language.default
    KnownUri.add_to_data(@virtuoso_results)
    DataPointUri.preload_data_point_uris!(@virtuoso_results)
    @data_point_uris = @virtuoso_results.collect{ |r| r[:data_point_instance] }
    DataPointUri.preload_associations(@data_point_uris, [ :comments, :taxon_data_exemplars, { :resource => :content_partner } ])
    DataPointUri.preload_associations(@data_point_uris.select{ |d| d.association? }, :target_taxon_concept =>
      [ { :preferred_common_names => :name },
        { :preferred_entry => { :hierarchy_entry => { :name => :ranked_canonical_form } } } ])
    sort
    @data_point_uris
  end

  def each
    @data_point_uris.each { |data_point_uri| yield(data_point_uri) }
  end

  def empty?
    @data_point_uris.nil? || @data_point_uris.empty?
  end

  # NOTE - this is 'destructive', since we don't ever need it to not be. If that changes, make the corresponding method and add a bang to this one.
  def sort
    last = KnownUri.count + 2
    @data_point_uris.sort_by! do |data_point_uri|
      attribute_label = EOL::Sparql.uri_components(data_point_uri.predicate)[:label]
      attribute_pos = data_point_uri.predicate_known_uri ? data_point_uri.predicate_known_uri.position : last
      value_label = EOL::Sparql.uri_components(data_point_uri.object)[:label]
      attribute_label = safe_downcase(attribute_label)
      value_label = safe_downcase(value_label)
      [ attribute_pos, attribute_label, value_label ]
    end
  end

  def safe_downcase(what)
    what = what.to_s if what.respond_to?(:to_s)
    what.downcase if what.respond_to?(:downcase)
  end

  def delete_if(&block)
    @data_point_uris.delete_if { |data_point_uri| yield(data_point_uri) }
  end

  # TODO - in my sample data (which had a single duplicate value for 'weight'), running this then caused the "more"
  # to go away.  :\  We may not care about such cases, though.
  def uniq
    h = {}
    @data_point_uris.each { |data_point_uri| h["#{data_point_uri.predicate}:#{data_point_uri.object}"] = data_point_uri }
    @data_point_uris = h.values
    self # Need to return self in order to get chains to work.  :\
  end

  def data_point_uris
    @data_point_uris.dup
  end

end
