class Administrator::UserController  < AdminController

  access_control :DEFAULT => 'Administrator - Web Users'

  
  def index
    
    @user_search_string=params[:user_search_string] || ''
    search_string_parameter='%' + @user_search_string + '%' 
    @users=User.paginate(
      :conditions=>['email like ? OR username like ? OR given_name like ? OR identity_url like ? OR family_name like ? OR username like ?',
        search_string_parameter,
       search_string_parameter,
       search_string_parameter,
       search_string_parameter,
       search_string_parameter,
       search_string_parameter],
      :order=>'created_at desc',:page => params[:page])
    @user_count=User.count(
      :conditions=>['email like ? OR username like ? OR given_name like ? OR identity_url like ? OR family_name like ? OR username like ?',
      search_string_parameter,
      search_string_parameter,
      search_string_parameter,
      search_string_parameter,
      search_string_parameter,
      search_string_parameter])
    
  end
  
  def edit
    
    @user=User.find(params[:id])
    
  end
  
  def new  
    @user=User.create_new
  end
  
  def create
    
    @user=User.create_new(params[:user])
    
    @user.password=@user.entered_password
    params[:user][:role_ids] ||= []
    
    if @user.save
      flash[:notice]="The new user was created."
      redirect_to :action=>'index'
    else
      render :action=>'new'
    end
    
  end
  
  def update
  
   @user = User.find(params[:id])  
   @user.password=params[:user][:entered_password] unless params[:user][:entered_password].blank? && params[:user][:entered_password_confirmation].blank?
   @user.set_curator(params[:user][:curator_approved],current_user)
   if @user.update_attributes(params[:user])
      flash[:notice]="The user was updated."
      redirect_to :action=>'index' 
    else
      render :action=>'edit'
    end
  end
  

 def destroy

   (redirect_to :action=>'index';return) unless request.method == :delete
   
   @user = User.find(params[:id])
   @user.destroy

   redirect_to :action=>'index' 
 end
 
  def toggle_curator
    
    id = params[:user][:id]
    @user = User.find(id)
    @user.set_curator(!params[:user][:curator_approved].nil?,current_user)
    @user.save!
  
  end
    
end
