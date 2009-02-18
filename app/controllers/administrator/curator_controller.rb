class Administrator::CuratorController < AdminController

  access_control :DEFAULT => 'Administrator - Web Users'
    
  def index
    @user_search_string=params[:user_search_string] || ''
    search_string_parameter='%' + @user_search_string + '%' 
    
    @users=User.paginate(
                         :conditions=>['curator_hierarchy_entry_id IS NOT NULL AND (email like ? OR username like ? OR given_name like ? OR identity_url like ? OR family_name like ? OR username like ?)',
    search_string_parameter,
    search_string_parameter,
    search_string_parameter,
    search_string_parameter,
    search_string_parameter,
    search_string_parameter],
    :order=>'curator_approved ASC, created_at DESC',:page => params[:page])
    @user_count=User.count(
                           :conditions=>['curator_hierarchy_entry_id IS NOT NULL AND (email like ? OR username like ? OR given_name like ? OR identity_url like ? OR family_name like ? OR username like ?)',
    search_string_parameter,
    search_string_parameter,
    search_string_parameter,
    search_string_parameter,
    search_string_parameter,
    search_string_parameter])
    
  end
  
end
