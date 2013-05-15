class Taxa::DataController < TaxaController

  before_filter :instantiate_taxon_page, :redirect_if_superceded, :instantiate_preferred_names
  before_filter :add_page_view_log_entry

  def index
    @assistive_section_header = "ASdfsfasdfasdfasdaf" # TODO
    @recently_used = KnownUri.where(['uri IN (?)', session[:rec_uris]]) if session[:rec_uris]
    @data = replace_licenses_with_mock_known_uris(@taxon_page.data.get_data)
    @categories = @data.map { |d| d[:attribute] }.flat_map { |a| a.is_a?(KnownUri) ? a.toc_items : nil }.uniq.compact
    current_user.log_activity(:viewed_taxon_concept_data, :taxon_concept_id => @taxon_concept.id)
  end

protected

  # TODO - move this to TaxonData.
  def replace_licenses_with_mock_known_uris(data)
    data.each do |row|
      row[:metadata].each do |key, val|
        if key == UserAddedDataMetadata::LICENSE_URI && license = License.find_by_source_url(val.to_s)
          row[:metadata][key] = KnownUri.new(:uri => val,
            :translations => [ TranslatedKnownUri.new(:name => license.title, :language => current_language) ])
        end
      end
    end
    data
  end

  def meta_description
    topics = @data.map { |d| d[:attribute] }.select { |a| a.is_a?(KnownUri) }.uniq.compact.map(&:name)
    translation_vars = scoped_variables_for_translations.dup
    translation_vars[:topics] = topics.join("; ") unless topics.empty?
    I18n.t("meta_description#{translation_vars[:topics] ? '_with_topics' : '_no_data'}", translation_vars)
  end

end
