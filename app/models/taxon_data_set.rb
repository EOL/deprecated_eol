# Basically, I made this quick little class because the sort method required in two places and it didn't belong in one or t'other.
class TaxonDataSet

  include Enumerable

  def initialize(rows, options = {})
    @rows = rows
    @taxon_concept_id = options[:taxon_concept_id]
    @language = options[:language] || Language.default
    preload_data_point_uris
    add_user_added_data
    add_resource_ids
    preload_resources
    KnownUri.add_to_data(@rows)
    KnownUri.replace_taxon_concept_uris(@rows)
    TaxonData.preload_target_taxon_concepts(@rows)
    @rows.sort
  end

  def each
    @rows.each { |row| yield(row) }
  end

  def empty?
    @rows.nil? || @rows.empty?
  end

  # NOTE - this is 'destructive', since we don't ever need it to not be. If that changes, make the corresponding method and add a bang to this one.
  def sort
    last = KnownUri.count + 2
    @rows.sort_by! do |row|
      attribute_label = EOL::Sparql.uri_components(row[:attribute].to_s)[:label]
      attribute_pos = row[:attribute].is_a?(KnownUri) ? row[:attribute].position : last
      value_label = EOL::Sparql.uri_components(row[:value].to_s)[:label]
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

  def preload_resources
    resources = Resource.find_all_by_id(@rows.collect{ |r| r[:resource_id] }.compact.uniq, :include => :content_partner)
    @rows.each do |row|
      if resource_id = row[:resource_id].to_i
        if resource = resources.detect{ |r| r.id == resource_id }
          row[:source] = resource.content_partner
        end
      end
    end
  end

  def add_user_added_data
    @rows.each do |row|
      if user_added_data = UserAddedData.from_value(row[:data_point_uri])
        row[:user] = user_added_data.user
        row[:user_added_data] = user_added_data
        row[:source] = row[:user]
      end
    end
  end

  def add_resource_ids
    @rows.each do |row|
      row[:resource_id] = row[:graph].to_s.split("/").last if row[:graph]
    end
  end

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
