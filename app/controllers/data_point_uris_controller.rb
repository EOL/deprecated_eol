class DataPointUrisController < ApplicationController

  before_filter :load_uri

  layout 'v2/basic'

  def hide
    @data_point_uri.hide(current_user)
    # TODO - log activity
    redirect_to taxon_data_path(@data_point_uri.taxon_concept)
  end

  # Again, 'unhide' to avoid clash with 'show'... not that we need #show, here, but it's conventional.
  def unhide
    @data_point_uri.show(current_user)
    # TODO - log activity
    redirect_to taxon_data_path(@data_point_uri.taxon_concept)
  end

private

  def load_uri
    @data_point_uri = DataPointUri.find(params[:data_point_uri_id] || params[:id])
  end

end
