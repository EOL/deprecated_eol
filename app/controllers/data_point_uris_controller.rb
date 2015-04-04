class TraitsController < ApplicationController

  before_filter :restrict_to_data_viewers
  before_filter :load_uri
  skip_before_filter :original_request_params, :global_warning, :check_user_agreed_with_terms, :keep_home_page_fresh, only: :show_metadata

  layout 'basic'

  def hide
    @trait.hide(current_user)
    log_action(:hide)
    respond_to do |format|
      format.html do
        redirect_to taxon_data_path(@trait.taxon_concept)
      end
      format.js { }
    end
  end

  # Again, 'unhide' to avoid clash with 'show'... not that we need #show, here, but it's conventional.
  def unhide
    @trait.show(current_user)
    log_action(:unhide)
    respond_to do |format|
      format.html do
        redirect_to taxon_data_path(@trait.taxon_concept)
      end
      format.js { }
    end
  end

  def show_metadata
    render(partial: 'metadata')
  end

private

  def load_uri
    @trait = Trait.find(params[:trait_id] || params[:id])
  end

  def log_action(method)
    CuratorActivityLog.create(
      user_id: current_user.id,
      changeable_object_type: ChangeableObjectType.trait,
      target_id: @trait.id,
      activity: Activity.send(method),
      taxon_concept_id: @trait.taxon_concept_id
    )
  end

end
