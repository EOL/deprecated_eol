class DataSearchFilesController < ApplicationController

  before_filter :restrict_to_data_viewers

  before_filter :set_page_title

  layout 'v2/basic'

  def index
    @background_processes = if current_user.is_admin? || current_user.min_curator_level?(:master)
      DataSearchFile.all
    else
      DataSearchFile.where(user_id: current_user.id)
    end
    # TODO - pagination
  end

  def destroy
    @data_search_file = DataSearchFile.find(params[:id])
    if @data_search_file.user == current_user || current_user.is_admin? || current_user.min_curator_level?(:master)
      @data_search_file.destroy
      flash[:notice] = I18n.t(:data_search_destroyed)
    else
      raise EOL::Exceptions::SecurityViolation
    end
    redirect_to action: :index
  end

  private

  def set_page_title
    @page_title = I18n.t(:background_processes_page_title)
  end

end
