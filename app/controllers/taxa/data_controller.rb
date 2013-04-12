class Taxa::DataController < TaxaController

  before_filter :instantiate_taxon_page, :redirect_if_superceded, :instantiate_preferred_names
  before_filter :add_page_view_log_entry

  autocomplete :known_uri, :uri
  autocomplete :translated_known_uri, :name

  def index
    @assistive_section_header = "ASdfsfasdfasdfasdaf" # TODO
    @data = @taxon_page.data.get_data
    # TODO - I don't think we want #selectable_toc, but I'm not sure what we do want.
    @categories = TocItem.selectable_toc.select { |r| ! r.label.blank? }.sort_by(&:label)
    current_user.log_activity(:viewed_taxon_concept_data, :taxon_concept_id => @taxon_concept.id)
  end

protected

  # TODO...
  def meta_description
    @meta_description ||= "this is so meta"
  end

end
