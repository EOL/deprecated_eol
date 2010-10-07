class Administrator::UserDataObjectController < AdminController  

  layout 'left_menu'

  before_filter :set_layout_variables

  def index

    @page_title = 'User Submitted Text'
 
    @user_id=params[:user_id] || 'All'
    @user_list=User.users_with_submitted_text
    
    @object_ids = UsersDataObject.get_user_submitted_data_object_ids(@user_id)
    @obj_toc_info = DataObject.get_toc_info(@object_ids)
    
    if(@user_id.downcase == 'all') then    
      @comments = UsersDataObject.paginate_by_sql("SELECT udo.* FROM users_data_objects udo JOIN #{DataObject.full_table_name} do ON (udo.data_object_id=do.id) ORDER BY udo.id DESC", :page => params[:page])
      @comment_count = SpeciesSchemaModel.connection.execute("SELECT COUNT(*) FROM #{UsersDataObject.full_table_name} udo JOIN #{DataObject.full_table_name} do ON (udo.data_object_id=do.id)").fetch_row[0]
    else
      @comments = UsersDataObject.paginate_by_sql("SELECT udo.* FROM users_data_objects udo JOIN #{DataObject.full_table_name} do ON (udo.data_object_id=do.id) WHERE udo.user_id=#{@user_id} ORDER BY udo.id DESC", :page => params[:page])
      @comment_count = SpeciesSchemaModel.connection.execute("SELECT COUNT(*) FROM #{UsersDataObject.full_table_name} udo JOIN #{DataObject.full_table_name} do ON (udo.data_object_id=do.id) WHERE udo.user_id=#{@user_id}").fetch_row[0]
    end
    
  end
  
private

  def set_layout_variables
    @page_title = $ADMIN_CONSOLE_TITLE
    @navigation_partial = '/admin/navigation'
  end

end
