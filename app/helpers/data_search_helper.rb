module DataSearchHelper

  def data_search_attribute_options
    select_options = []
    if @taxon_concept && TaxonData.is_clade_searchable?(@taxon_concept)
      # Get URIs (attributes) that this clade has measurements or facts for.
      # NOTE excludes associations URIs e.g. preys upon.
      measurement_uris = EOL::Sparql.connection.all_measurement_type_known_uris_for_clade(@taxon_concept)
    else
      # NOTE - because we're pulling this from Sparql, user-added known uris may not be included. However, it's superior to
      # KnownUri insomuch as it ensures that KnownUris with NO data are ignored.
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
    if @attribute.nil?
      # NOTE we should (I assume) only get nil attribute when the user first
      #      loads the search, so for that context we select an example default,
      #      starting with [A-Z] seems more readable. If my assumption is wrong
      #      then we should rethink this and tell the user why attribute is nil
      @attribute = select_options.select{|o| o[0] =~ /^[A-Z]/}.first[1] rescue nil
    end
    options_for_select(select_options, @attribute)
  end

  def data_search_results_summary
    search_term_to_show = [
      (@attribute_known_uri ? @attribute_known_uri.label.firstcap : @attribute),
      @querystring ].delete_if{ |t| t.blank? }.join(' : ')
    summary = I18n.t(:count_results_for_search_term,
      count: @results.total_entries,
      search_term: h(search_term_to_show))
    if @taxon_concept && TaxonData.is_clade_searchable?(@taxon_concept)
      summary << ' ' + I18n.t(:searching_within_clade,
        clade_name: link_to(raw(@taxon_concept.title_canonical_italicized),
        taxon_overview_url(@taxon_concept)))
    end
    raw summary
  end

end
