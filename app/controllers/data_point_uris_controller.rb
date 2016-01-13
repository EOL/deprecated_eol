class DataPointUrisController < ApplicationController

  before_filter :restrict_to_data_viewers
  before_filter :load_uri
  skip_before_filter :original_request_params, :global_warning, :check_user_agreed_with_terms, :keep_home_page_fresh, only: :show_metadata
  after_filter :flush_cached_data, only: [:hide, :unhide]
  layout 'basic'

  def hide
    @data_point_uri.hide(current_user)
    log_action(:hide)
    # TaxonDataExemplar.remove(@data_point_uri)
    # TODO - log activity
    respond_to do |format|
      format.html do
        redirect_to taxon_data_path(@data_point_uri.taxon_concept)
      end
      format.js { }
    end
  end

  # Again, 'unhide' to avoid clash with 'show'... not that we need #show, here, but it's conventional.
  def unhide
    @data_point_uri.show(current_user)
    # TODO - log activity
    log_action(:unhide)
    respond_to do |format|
      format.html do
        redirect_to taxon_data_path(@data_point_uri.taxon_concept)
      end
      format.js { }
    end
  end

  def show_metadata
    render(partial: 'metadata')
  end

private

  def load_uri
    @data_point_uri = DataPointUri.find(params[:data_point_uri_id] || params[:id])
  end

  def log_action(method)
    CuratorActivityLog.create(
      user_id: current_user.id,
      changeable_object_type: ChangeableObjectType.data_point_uri,
      target_id: @data_point_uri.id,
      activity: Activity.send(method),
      taxon_concept_id: @data_point_uri.taxon_concept_id
    )
  end

  def flush_cached_data
    expire_fragment("taxa/#{@data_point_uri.taxon_concept.id}/data_view", skip_digest: true)
  end
end
