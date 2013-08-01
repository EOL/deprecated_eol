class Taxa::MediaController < TaxaController

  before_filter :instantiate_taxon_page, :redirect_if_superceded, :instantiate_preferred_names
  before_filter :add_page_view_log_entry

  def index
    # NOTE - whitelisting the params. Don't be lazy and just pass params, here!
    @taxon_media = @taxon_page.media(page: params[:page],
                                     per_page: params[:per_page],
                                     sort_by: params[:sort_by],
                                     type: params[:type],
                                     status: params[:status])

    # TODO - current_user_ratings is unnecessary. We could handle this easily with duck-typing, but I don't want to do that right now:
    @current_user_ratings = @taxon_media.applied_ratings
    @assistive_section_header = I18n.t(:assistive_media_header)
    set_canonical_urls(:for => @taxon_page, :paginated => @media, :url_method => :taxon_media_url)
    current_user.log_activity(:viewed_taxon_concept_media, :taxon_concept_id => @taxon_concept.id)
  end

protected

  def meta_description
    @meta_description ||= t(".meta_description#{scoped_variables_for_translations[:preferred_common_name] ? '_with_common_name' : ''}#{@media.blank? ? '_no_data' : ''}", scoped_variables_for_translations.dup)
  end

end
