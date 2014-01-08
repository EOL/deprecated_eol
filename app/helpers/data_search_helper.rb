module DataSearchHelper

  def data_search_attribute_options
    select_options = [ I18n.t(:not_specified), nil ]
    if @taxon_data # All of the attributes on this data:
      measurement_uris = @taxon_data.get_data.map(&:predicate_uri)
    elsif @taxon_concept # NOTE - I didn't write this, but I think the intent here is to get ONLY attributes with numeric values:
      measurement_uris = TaxonData.new(@taxon_concept, current_user).ranges_of_values.collect{ |r| r[:attribute] }
    else
      measurement_uris = EOL::Sparql.connection.all_measurement_type_known_uris
    end
    # TODO - this could be greatly simplified with duck-typing.  :|
    select_options += measurement_uris.collect do |uri|
      label = uri.respond_to?(:name) ? uri.name : EOL::Sparql.uri_to_readable_label(uri)
      if label.nil?
        nil
      else
        [ truncate(label.firstcap, length: 30),
          uri.respond_to?(:uri) ? uri.uri : uri,
          { 'data-known_uri_id' => uri.respond_to?(:id) ? uri.id : nil } ]
      end
    end.compact.sort_by{ |o| o.first }.uniq
    options_for_select(select_options, @attribute)
  end

end
