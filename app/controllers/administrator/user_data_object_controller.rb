class Administrator::UserDataObjectController < AdminController

  layout 'left_menu'

  before_filter :set_layout_variables

  before_filter :restrict_to_admins

  def index
    @page_title = I18n.t("user_submitted_text_")
    @user_id = params[:user_id] || 'All'
    @user_list = User.users_with_submitted_text

    conditions = (@user_id == 'All') ? nil : ['user_id = ?',@user_id]
    @users_data_objects = UsersDataObject.paginate(:conditions => conditions,
      :order => 'id desc',
      :select => {
        :users_data_objects => :taxon_concept_id,
        :users => [ :given_name, :family_name ],
        :data_objects => [ :description, :created_at, :updated_at, :published ] },
      :include => [ :user, { :data_object => [ :vetted, :visibility, :toc_items] }],
      :page => params[:page])
  end

private

  def set_layout_variables
    @page_title = $ADMIN_CONSOLE_TITLE
    @navigation_partial = '/admin/navigation'
  end

end
