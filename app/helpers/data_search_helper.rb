module DataSearchHelper

  def data_search_attribute_options
    select_options = { "-- " + I18n.t('activerecord.attributes.user_added_data.predicate') + " --" => nil }
    if @taxon_data # All of the attributes on this data:
      measurement_uris = @taxon_data.get_data.map(&:predicate_uri)
    elsif @taxon_concept # NOTE - I didn't write this, but I think the intent here is to get ONLY attributes with numeric values:
      measurement_uris = TaxonData.new(@taxon_concept, current_user).ranges_of_values.collect{ |r| r[:attribute] }
    else
      measurement_uris = EOL::Sparql.connection.all_measurement_type_known_uris
    end
    # TODO - this could be greatly simplified with duck-typing.  :|
    select_options = select_options.merge(Hash[ measurement_uris.collect do |uri|
      label = uri.respond_to?(:name) ? uri.name : EOL::Sparql.uri_to_readable_label(uri)
      label.nil? ? nil : [ label.firstcap, uri.respond_to?(:uri) ? uri.uri : uri ]
    end.compact.sort_by{ |k,v| k.nil? ? '' : k } ] )
    options_for_select(select_options.map { |opt| [ truncate(opt[0], length: 30), opt[1] ]}, @attribute)
  end

end
