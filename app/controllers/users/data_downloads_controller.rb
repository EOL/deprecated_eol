class Users::DataDownloadsController < UsersController

  include DataSearchHelper

  skip_before_filter :extend_for_open_authentication
  before_filter :instantiate_user  
  before_filter :show_explanation_to_admins
  helper_method :able_to_edit_user?

  def index
    # NOTE this #joins avoids the problem where known_uri can be nil. Don't remove it unless you choose to clean that mess:
    @background_processes = DataSearchFile.where(user_id: @user.id).joins(:known_uri).order('updated_at desc')
    @rel_canonical_href = user_data_downloads_url(@user)
  end

  def destroy
    @data_search_file = DataSearchFile.find(params[:id])
    if @data_search_file.user == current_user || current_user.is_admin? || current_user.min_curator_level?(:master)
      @data_search_file.destroy
      flash[:notice] = I18n.t(:data_search_destroyed)
    else
      # TODO - second argument to constructor should be an I18n key for a human-readable error.
      raise EOL::Exceptions::SecurityViolation
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
    flash.now[:notice] = I18n.t(:warning_you_are_editing_as_admin) if able_to_edit_user?
  end

end
