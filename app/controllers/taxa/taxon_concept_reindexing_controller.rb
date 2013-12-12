class Taxa::TaxonConceptReindexingController < TaxaController

  before_filter :instantiate_taxon_page, :redirect_if_superceded, :instantiate_preferred_names
  before_filter :restrict_to_master_curators

  def create
    begin
      TaxonConceptReindexing.reindex(@taxon_concept)
      flash[:notice] = I18n.t(:this_page_will_be_reindexed)
    rescue EOL::Exceptions::ClassificationsLocked
      flash.now[:error] = I18n.t(:error_classifications_locked_cannot_reindex)
    rescue EOL::Exceptions::TooManyDescendantsToCurate => e # Wonky, but true: the error msg contains the count
      flash.now[:error] = I18n.t(:too_many_descendants_to_curate_with_count, count: e.message.to_i)
    end
    respond_to do |format|
      format.html do
        redirect_to taxon_overview_url(@taxon_concept)
      end
      format.js do
        convert_flash_messages_for_ajax
        render partial: 'shared/flash_messages', layout: false # JS will handle rendering these.
      end
    end
  end

end
