class Taxa::MediaController < TaxaController

  before_filter :instantiate_taxon_page, :redirect_if_superceded, :instantiate_preferred_names

  def index
    # NOTE - whitelisting the params. Don't be lazy and just pass params, here!
     examplar = @taxon_concept.exemplar_or_best_image_from_solr
     options = { page: params[:page],per_page: params[:per_page], sort_by: params[:sort_by], type: params[:type], status: params[:status] }
  
    if examplar
      @taxon_media = @taxon_page.media(options.merge(examplar_id: examplar.id)) # skip examplar images from media
    else
      @taxon_media = @taxon_page.media(options)
    end
    
    @assistive_section_header = I18n.t(:assistive_media_header)
    set_canonical_urls(for: @taxon_page, paginated: @taxon_media.paginated, url_method: :taxon_media_url)
    current_user.log_activity(:viewed_taxon_concept_media, taxon_concept_id: @taxon_concept.id)
  end

  # Can't test this if private:
  def meta_description
    @meta_description ||= t(".meta_description#{scoped_variables_for_translations[:preferred_common_name] ? '_with_common_name' : ''}#{@taxon_media.empty? ? '_no_data' : ''}", scoped_variables_for_translations.dup)
  end

end
