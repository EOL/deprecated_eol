class Administrator::UserDataObjectController < AdminController  


  def index
 
    @user_id=params[:user_id] || 'all'
    @user_list=User.users_with_submitted_text
    if(@user_id == 'all') then    
      @comments=UsersDataObject.paginate(:order=>'id desc',:include=>:user,:page => params[:page])
      @comment_count=UsersDataObject.count()
    else
      @comments=UsersDataObject.paginate(:conditions=>['user_id = ?',@user_id], :order=>'id desc',:include=>:user,:page => params[:page])
      @comment_count=UsersDataObject.count(:conditions=>['user_id = ?',@user_id])      
    end
    
  end
  
  
end
