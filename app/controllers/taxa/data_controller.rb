class Taxa::DataController < TaxaController

  before_filter :instantiate_taxon_page, :redirect_if_superceded, :instantiate_preferred_names
  before_filter :add_page_view_log_entry

  def index
    @assistive_section_header = "ASdfsfasdfasdfasdaf" # TODO
    @recently_used = KnownUri.where(['uri IN (?)', session[:rec_uris]]) if session[:rec_uris]
    @data = @taxon_page.data.get_data
    # bulk preloading of resources/content partners
    preload_data_point_uris
    # bulk preloading of associated taxa
    preload_associations

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

  def preload_associations
    associations_data = @data.select{ |d| d.has_key?(:target_taxon_concept_id) }
    taxon_concepts = TaxonConcept.find_all_by_id(associations_data.collect{ |d| d[:target_taxon_concept_id] }.compact.uniq, :include => { :preferred_common_names => :name })
    associations_data.each do |d|
      if taxon_concept = taxon_concepts.detect{ |tc| tc.id.to_s == d[:target_taxon_concept_id] }
        d[:target_taxon_concept] = taxon_concept
      end
    end
  end

end
