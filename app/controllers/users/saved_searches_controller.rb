class Users::SavedSearchesController < UsersController

  skip_before_filter :extend_for_open_authentication
  before_filter :instantiate_user
  before_filter :must_be_able_to_edit_this_user

  def index
    @background_processes = DataSearchFile.where(user_id: @user.id).order('updated_at desc')
    @rel_canonical_href = user_saved_searches_url(@user)
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

  # GET /users/:user_id/saved_searches/:id/refresh
  def refresh
    if data_search_file = DataSearchFile.find(params[:id])
      data_search_file.hosted_file_url = nil
      data_search_file.row_count = nil
      data_search_file.completed_at = nil
      data_search_file.save
      Resque.enqueue(DataFileMaker, data_file_id: data_search_file.id)
      flash[:notice] = I18n.t(:file_download_refreshing, link: user_saved_searches_path(current_user.id))
    end
    redirect_to action: :index
  end

  private

  def instantiate_user
    @user = User.find(params[:user_id])
    redirect_if_user_is_inactive
    preload_user_associations
  end

  def must_be_able_to_edit_this_user
    raise EOL::Exceptions::SecurityViolation,
      "User with ID=#{current_user.id} does not have edit access to User with ID=#{@user.id}" unless current_user.can_update?(@user)
  end

end
