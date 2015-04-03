module DataSearchHelper

  def data_search_results_summary
    return "" if @results.nil?
    search_term_to_show = [
      (@attribute_known_uri ? @attribute_known_uri.label : @attribute),
      # NOTE - I think the hard-coded colon is okay here. It's just a visual separator with no value.
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
                val: display_text_for_trait(search_file.from_as_data_point))
    end
    unless search_file.to.nil?
      summary_parts << I18n.t('helpers.label.data_search.max_with_val',
                val: display_text_for_trait(search_file.to_as_data_point))
    end
    if search_file.complete?
      summary_parts << I18n.t('helpers.label.data_search.total_results',
                              total: number_with_delimiter(search_file.row_count || 0))
    end
    summary_parts
  end

end
