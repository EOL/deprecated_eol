class DataPointUrisController < ApplicationController

  before_filter :restrict_to_data_viewers
  before_filter :load_uri
  skip_before_filter :original_request_params, :global_warning, :check_user_agreed_with_terms, :keep_home_page_fresh, only: :show_metadata

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
    curator_activity_log = CuratorActivityLog.create(
      user_id: current_user.id,
      changeable_object_type: ChangeableObjectType.data_point_uri,
      target_id: @data_point_uri.id,
      activity: Activity.send(method),
      taxon_concept_id: @data_point_uri.taxon_concept_id
    )
    queue_notifications(curator_activity_log)
  end

  def queue_notifications(action)
    Notification.queue_notifications( notification_recipient_objects, action)
  end
  def notification_recipient_objects
    return @notification_recipients if @notification_recipients
    @notification_recipients = []
    add_recipient_partner_owner_of_resource(@notification_recipients)
    @notification_recipients
  end

  def add_recipient_partner_owner_of_resource(recipients)
    if @data_point_uri.source.is_a?(ContentPartner)
      @data_point_uri.source.user.add_as_recipient_if_listening_to(:curation_on_my_content_partner_data, recipients)
    end
  end
end
