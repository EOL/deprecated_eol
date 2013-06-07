class Taxa::DataController < TaxaController

  before_filter :instantiate_taxon_page, :redirect_if_superceded, :instantiate_preferred_names
  before_filter :add_page_view_log_entry

  def index
    @assistive_section_header = "ASdfsfasdfasdfasdaf" # TODO
    @recently_used = KnownUri.where(['uri IN (?)', session[:rec_uris]]) if session[:rec_uris]
    @data = @taxon_page.data.get_data
    partner_data = @data.select{ |d| d.has_key?(:data_point_uri) }
    partner_data.each do |d|
      d[:data_point_instance] = DataPointUri.find_or_create_by_taxon_concept_id_and_uri(@taxon_page.taxon_concept.id, d[:data_point_uri].to_s)
    end
    DataPointUri.preload_associations(partner_data.collect{ |d| d[:data_point_instance] }, :all_comments)

    @show_download_data_button = true unless @data.blank?
    @categories = @data.map { |d| d[:attribute] }.flat_map { |a| a.is_a?(KnownUri) ? a.toc_items : nil }.uniq.compact
    current_user.log_activity(:viewed_taxon_concept_data, :taxon_concept_id => @taxon_concept.id)
  end

protected

  def meta_description
    topics = @data.map { |d| d[:attribute] }.select { |a| a.is_a?(KnownUri) }.uniq.compact.map(&:name)
    translation_vars = scoped_variables_for_translations.dup
    translation_vars[:topics] = topics.join("; ") unless topics.empty?
    I18n.t("meta_description#{translation_vars[:topics] ? '_with_topics' : '_no_data'}", translation_vars)
  end

end
