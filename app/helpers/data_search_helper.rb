module DataSearchHelper

  def data_search_results_summary
    return "" if @results.nil?
    search_term_to_show = [
      @attributes,
      # NOTE - I think the hard-coded colon is okay here. It's just a visual separator with no value.
      @values ].delete_if{ |t| t.blank? }.join(' : ')
      
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

  def data_search_file_summary(search_file)
    summary_parts = []
    unless search_file.q.blank?
      summary_parts << I18n.t('helpers.label.data_search.q_with_val', val: search_file.q)
    end
    if search_file.taxon_concept
      summary_parts << I18n.t('helpers.label.data_search.taxon_name_with_val',
                val: link_to(raw(search_file.taxon_concept.title_canonical_italicized),
                             taxon_overview_url(search_file.taxon_concept)))
    end
    unless search_file.from.nil?
      summary_parts << I18n.t('helpers.label.data_search.min_with_val',
                val: display_text_for_data_point_uri(search_file.from_as_data_point))
    end
    unless search_file.to.nil?
      summary_parts << I18n.t('helpers.label.data_search.max_with_val',
                val: display_text_for_data_point_uri(search_file.to_as_data_point))
    end
    if search_file.complete?
      summary_parts << I18n.t('helpers.label.data_search.total_results',
                              total: number_with_delimiter(search_file.row_count || 0))
    end
    summary_parts
  end

  # todo improve this hacky way of handling empty attributes
  def prepare_attribute_options
    @attribute_options = []
    if @taxon_concept && TaxonData.is_clade_searchable?(@taxon_concept)
      # Get URIs (attributes) that this clade has measurements or facts for.
      # NOTE excludes associations URIs e.g. preys upon.
      measurement_uris = EOL::Sparql.connection.all_measurement_type_known_uris_for_clade(@taxon_concept)
      @attribute_options = convert_uris_to_options(measurement_uris)
      @clade_has_no_data = true if @attribute_options.blank?
    end

    if @attribute_options.blank?
      # NOTE - because we're pulling this from Sparql, user-added known uris may not be included. However, it's superior to
      # KnownUri insomuch as it ensures that KnownUris with NO data are ignored.
      measurement_uris = EOL::Sparql.connection.all_measurement_type_known_uris
      @attribute_options = convert_uris_to_options(measurement_uris)
    end

    if @attribute.blank?
      # NOTE we should (I assume) only get nil attribute when the user first
      #      loads the search, so for that context we select an example default,
      #      starting with [A-Z] seems more readable. If my assumption is wrong
      #      then we should rethink this and tell the user why attribute is nil
      match = @attribute_options.select{|o| o[0] =~ /^[A-Z]/}
      @attribute_default = match.first[1] unless match.blank?
    end
  end

  def convert_uris_to_options(measurement_uris)
    # TODO - this could be greatly simplified with duck-typing.  :|
    measurement_uris.collect do |uri|
      label = uri.respond_to?(:name) ? uri.name : EOL::Sparql.uri_to_readable_label(uri)
      if label.nil?
        nil
      else
        [ truncate(label, length: 30),
          uri.respond_to?(:uri) ? uri.uri : uri,
          { 'data-known_uri_id' => uri.respond_to?(:id) ? uri.id : nil } ]
      end
    end.compact.sort_by { |o| o.first.downcase }.uniq
  end

  def prepare_search_parameters(options)
    @hide_global_search = true
    @querystring_uri = nil
    @querystring = readable_query_string(options[:q])
    @attribute = options[:attribute]
    @attribute_missing = @attribute.nil? && params.has_key?(:attribute)
    @sort = (options[:sort] && [ 'asc', 'desc' ].include?(options[:sort])) ? options[:sort] : 'desc'
    @unit = options[:unit].blank? ? nil : options[:unit]
    @min_value = (options[:min] && options[:min].is_numeric?) ? options[:min].to_f : nil
    @max_value = (options[:max] && options[:max].is_numeric?) ? options[:max].to_f : nil
    @min_value,@max_value = @max_value,@min_value if @min_value && @max_value && @min_value > @max_value
    @page = options[:page] || 1
    @required_equivalent_attributes = params[:required_equivalent_attributes]
    @required_equivalent_values = !options[:q].blank? ?  params[:required_equivalent_values] : nil 
    @equivalent_attributes = get_equivalents(@attribute)
    equivalent_attributes_ids = @equivalent_attributes.map{|eq| eq.id.to_s}
    # check if it is really an equivalent attribute
    @required_equivalent_attributes = @required_equivalent_attributes.map{|eq| eq if equivalent_attributes_ids.include?(eq) }.compact if @required_equivalent_attributes
    
    if !options[:q].blank?
      tku = TranslatedKnownUri.find_by_name(@querystring)
      ku = tku.known_uri if tku
      if ku
        @equivalent_values = get_equivalents(ku.uri)
        equivalent_values_ids = @equivalent_values.map{|eq| eq.id.to_s}
        @required_equivalent_values = @required_equivalent_values.map{|eq| eq if equivalent_values_ids.include?(eq) }.compact if @required_equivalent_values
      end
    end
    
    #if entered taxon name returns more than one result choose first
    if options[:taxon_concept_id].blank? && !(options[:taxon_name].blank?)
      results_with_suggestions = EOL::Solr::SiteSearch.simple_taxon_search(options[:taxon_name], language: current_language)
      results = results_with_suggestions[:results]
      if !(results.blank?)
        @taxon_concept = results[0]['instance']
      end
    end

    @taxon_concept ||= TaxonConcept.find_by_id(options[:taxon_concept_id])
    # Look up attribute based on query
    unless @querystring.blank? || EOL::Sparql.connection.all_measurement_type_uris.include?(@attribute)
      @attribute_known_uri = KnownUri.by_name(@querystring).first
      if @attribute_known_uri
        @attribute = @attribute_known_uri.uri
        @querystring = options[:q] = ''
      end
    else
      @attribute_known_uri = KnownUri.find_by_uri(@attribute)
    end
    @attributes = @attribute_known_uri ? @attribute_known_uri.label : @attribute
    if @required_equivalent_attributes
      @required_equivalent_attributes.each do |attr|
        @attributes += " + #{KnownUri.find(attr.to_i).label}"
      end
    end
    
    @values = @querystring.to_s
    if @required_equivalent_values
      @required_equivalent_values.each do |val|
        @values += " + #{KnownUri.find(val.to_i).label}"
      end
    end
    
    if @attribute_known_uri && ! @attribute_known_uri.units_for_form_select.blank?
      @units_for_select = @attribute_known_uri.units_for_form_select
    else
      @units_for_select = KnownUri.default_units_for_form_select
    end
    @search_options = { querystring: @querystring, attribute: @attribute, min_value: @min_value, max_value: @max_value,
      unit: @unit, sort: @sort, language: current_language, taxon_concept: @taxon_concept, 
      required_equivalent_attributes: @required_equivalent_attributes, required_equivalent_values: @required_equivalent_values}
    @data_search_file_options = { q: @querystring, uri: @attribute, from: @min_value, to: @max_value,
      sort: @sort, known_uri: @attribute_known_uri, language: current_language,
      user: current_user, taxon_concept_id: (@taxon_concept ? @taxon_concept.id : nil),
      unit_uri: @unit}
  end

  def readable_query_string(string)
    unless string.blank?
      uri = KnownUri.find_by_uri(string)
      @querystring_uri = string if uri
      return uri.label if uri
    end
    string
  end

  def get_equivalents(uri)
    uri = KnownUri.find_by_uri(uri) 
    uri ? uri.equivalent_known_uris : []
  end
end
