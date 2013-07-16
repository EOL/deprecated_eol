# Basically, I made this quick little class because the sort method required in two places and it didn't belong in one or t'other.
class TaxonDataSet

  include Enumerable

  def initialize(rows, options = {})
    @rows = rows
    @taxon_concept_id = options[:taxon_concept_id]
    @language = options[:language] || Language.default
    preload_data_point_uris
  end

  def each
    @rows.each { |row| yield(row) }
  end

  # NOTE - this is 'destructive', since we don't ever need it to not be. If that changes, make the corresponding method and add a bang to this one.
  def sort
    @rows.sort_by! do |row|
      attribute_label = EOL::Sparql.uri_components(row[:attribute])[:label]
      value_label = EOL::Sparql.uri_components(row[:value])[:label]
      value_label = value_label.to_s.downcase if value_label.class == RDF::Literal
      [ attribute_label.downcase, value_label.downcase ]
    end
  end

  def delete_if(&block)
    @rows.delete_if { |row| yield(row) }
  end

  # TODO - in my sample data (which had a single duplicate value for 'weight'), running this then caused the "more"
  # to go away.  :\  We may not care about such cases, though.
  def uniq
    h = {}
    @rows.each { |r| h["#{r[:attribute]}:#{r[:value]}"] = r }
    @rows = h.values
    self # Need to return self in order to get chains to work.  :\
  end

  private

  def preload_data_point_uris
    partner_data = @rows.select{ |d| d.has_key?(:data_point_uri) }
    data_point_uris = DataPointUri.find_all_by_taxon_concept_id_and_uri(@taxon_concept_id, partner_data.collect{ |d| d[:data_point_uri].to_s }.compact.uniq)
    partner_data.each do |d|
      if data_point_uri = data_point_uris.detect{ |dp| dp.uri == d[:data_point_uri].to_s }
        d[:data_point_instance] = data_point_uri
      end
    end

    # NOTE - this is /slightly/ scary, as it generates new URIs on the fly
    partner_data.each do |d|
      d[:data_point_instance] ||= DataPointUri.find_or_create_by_taxon_concept_id_and_uri(@taxon_concept_id, d[:data_point_uri].to_s)
    end
    DataPointUri.preload_associations(partner_data.collect{ |d| d[:data_point_instance] }, [ :all_comments, :taxon_data_exemplars ] )
  end

end
