class Users::DataDownloadsController < UsersController

  include DataSearchHelper

  skip_before_filter :extend_for_open_authentication
  before_filter :instantiate_user
  before_filter :show_explanation_to_admins
  helper_method :able_to_edit_user?
  DATA_SEARCH_FILE_TYPE = 0
  COLLECTION_DOWNLOAD_FILE_TYPE = 1

  def index
    # NOTE this #joins avoids the problem where known_uri can be nil. Don't remove it unless you choose to clean that mess:
    @background_processes = DataSearchFile.where(user_id: @user.id).joins(:known_uri)
    @background_processes += CollectionDownloadFile.where(user_id: @user.id)
    @background_processes.sort_by!(&:updated_at).reverse!
    @rel_canonical_href = user_data_downloads_url(@user)
  end

  def destroy
    @data_file = params[:type] == DATA_SEARCH_FILE_TYPE ? DataSearchFile.find(params[:id]) : CollectionDownloadFile.find(params[:id])
    # if params[:type] == DATA_SEARCH_FILE_TYPE
      # @data_file = DataSearchFile.find(params[:id])
    # else
      # @data_file = CollectionDownloadFile.find(params[:id])
    # end
    if @data_file.user == current_user || current_user.is_admin? || current_user.min_curator_level?(:master)
      @data_file.destroy
      flash[:notice] = I18n.t(:data_search_destroyed)
    else 
      raise EOL::Exceptions::SecurityViolation.new("User with id = #{current_user.id} try to delete data file with id = #{@data_search_file}", 
      :missing_delete_access_to_data_search_file)
    end
    redirect_to action: :index
  end

  private

  def instantiate_user
    @user = User.find(params[:user_id])
    redirect_if_user_is_inactive
    preload_user_associations
  end

  def able_to_edit_user?
    current_user.can_update?(@user)
  end

  def show_explanation_to_admins
    flash.now[:notice] = I18n.t(:warning_you_are_editing_as_admin) if able_to_edit_user? && current_user != @user
  end

end
