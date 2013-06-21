class Taxa::DataController < TaxaController

  before_filter :instantiate_taxon_page, :redirect_if_superceded, :instantiate_preferred_names
  before_filter :add_page_view_log_entry

  def index
    @assistive_section_header = "ASdfsfasdfasdfasdaf" # TODO (see :assistive_overview_header for an example)
    @recently_used = KnownUri.where(['uri IN (?)', session[:rec_uris]]) if session[:rec_uris]
    @taxon_data = @taxon_page.data
    @data = @taxon_data.get_data
    @toc_id = params[:toc_id]
    # bulk preloading of resources/content partners
    preload_data_point_uris
    # bulk preloading of associated taxa
    @data = TaxonData.preload_target_taxon_concepts(@data)

    @show_download_data_button = ! @data.blank?
    @categories = TocItem.for_uris(current_language).select{ |toc| @taxon_data.categories.include?(toc) }
    @toc_id = nil unless @toc_id == 'other' || @categories.detect{ |toc| toc.id.to_s == @toc_id }
    current_user.log_activity(:viewed_taxon_concept_data, :taxon_concept_id => @taxon_concept.id)
  end

  def about
    # Sad that we need to load all of this, but TODO - we can cache this, later:
    @taxon_data = @taxon_page.data
    @data = @taxon_data.get_data
    @categories = TocItem.for_uris(current_language).select{ |toc| @taxon_data.categories.include?(toc) }
    @show_download_data_button = ! @categories.empty?
    respond_to do |format|
      format.html { }
      format.js { }
    end
  end

protected

  def meta_description
    topics = @data.map { |d| d[:attribute] }.select { |a| a.is_a?(KnownUri) }.uniq.compact.map(&:name)
    translation_vars = scoped_variables_for_translations.dup
    translation_vars[:topics] = topics.join("; ") unless topics.empty?
    I18n.t("meta_description#{translation_vars[:topics] ? '_with_topics' : '_no_data'}", translation_vars)
  end

  def preload_data_point_uris
    partner_data = @data.select{ |d| d.has_key?(:data_point_uri) }
    data_point_uris = DataPointUri.find_all_by_taxon_concept_id_and_uri(@taxon_page.taxon_concept.id, partner_data.collect{ |d| d[:data_point_uri].to_s }.compact.uniq)
    partner_data.each do |d|
      if data_point_uri = data_point_uris.detect{ |dp| dp.uri == d[:data_point_uri].to_s }
        d[:data_point_instance] = data_point_uri
      end
    end

    # NOTE - this is /slightly/ scary, as it generates new URIs on the fly
    partner_data.each do |d|
      d[:data_point_instance] ||= DataPointUri.find_or_create_by_taxon_concept_id_and_uri(@taxon_page.taxon_concept.id, d[:data_point_uri].to_s)
    end
    DataPointUri.preload_associations(partner_data.collect{ |d| d[:data_point_instance] }, :all_comments)
  end

end
