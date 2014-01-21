module DataSearchHelper

  def data_search_results_summary
    return "" if @results.nil?
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

  def data_graph_result_html(result)
    html = "<div class='google_chart'><a href='#{ result[:taxon_concept_id] }/data'>#{ result[:scientificName] }</a><br/>"
    if result[:data_point_uri].taxon_concept
      subtitle = result[:data_point_uri].taxon_concept.preferred_common_name_in_language(current_language)
      unless subtitle.blank?
        html += "#{subtitle}<br/>"
      end
      html += "#{ display_text_for_data_point_uri(result[:data_point_uri]).gsub(/\n/,'') }</div>"
    end
    html
  end

end
