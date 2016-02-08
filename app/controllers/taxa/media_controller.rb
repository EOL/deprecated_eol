class Taxa::MediaController < TaxaController

  before_filter :instantiate_taxon_page, :redirect_if_superceded, :instantiate_preferred_names

  def index
    # NOTE - whitelisting the params. Don't be lazy and just pass params, here!
     exemplar = @taxon_concept.exemplar_or_best_image_from_solr
     options = { page: params[:page],per_page: params[:per_page], sort_by: params[:sort_by], type: params[:type], status: params[:status] }
  
    if exemplar && (options[:type].blank? || filtered_by_images_or_all(options))
      options = options.merge(exemplar_id: exemplar.id) # skip exemplar images from media
    end
    @taxon_media = @taxon_page.media(options)
    @assistive_section_header = I18n.t(:assistive_media_header)
    set_canonical_urls(for: @taxon_page, paginated: @taxon_media.paginated, url_method: :taxon_media_url)
  end

  # Can't test this if private:
  def meta_description
    @meta_description ||= t("taxa.media.index.meta_description#{scoped_variables_for_translations[:preferred_common_name] ? '_with_common_name' : ''}#{@taxon_media.empty? ? '_no_data' : ''}",
     scoped_variables_for_translations.dup.except(:scope))
  end
  
  private
  def filtered_by_images_or_all(options)
    !options[:type].blank? && (options[:type].include?("image") || options[:type].include?("all"))  
  end
end
