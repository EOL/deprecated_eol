class Administrator::UserDataObjectController < AdminController

  layout 'deprecated/left_menu'

  before_filter :set_layout_variables

  before_filter :restrict_to_admins

  def index
    @page_title = I18n.t(:user_submitted_text)
    @user_id = params[:user_id] || 'All'
    @user_list = User.users_with_submitted_text

    conditions = (@user_id == 'All') ? nil : ['user_id = ?',@user_id]
    @users_data_objects = UsersDataObject.paginate(:conditions => conditions,
      :order => 'id desc',
      :include => [ :user, { :data_object => [:toc_items] }, :vetted, :visibility],
      :page => params[:page])
  end

private

  def set_layout_variables
    @page_title = $ADMIN_CONSOLE_TITLE
    @navigation_partial = '/admin/navigation'
  end

end
