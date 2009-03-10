class Administrator::UserController  < AdminController

  access_control :DEFAULT => 'Administrator - Web Users'

  def index
    
    @user_search_string=params[:user_search_string] || ''
    search_string_parameter='%' + @user_search_string + '%' 
    @start_date=params[:start_date] || "2008-02-26"
    @end_date=params[:end_date] || Date.today.to_s(:db)
  
    @users=User.paginate(
      :conditions=>['(created_at>=? AND created_at<=?) AND (id=? OR email like ? OR username like ? OR given_name like ? OR identity_url like ? OR family_name like ? OR username like ?)',
      @start_date,
      @end_date,
      @user_search_string,
      search_string_parameter,
       search_string_parameter,
       search_string_parameter,
       search_string_parameter,
       search_string_parameter,
       search_string_parameter],
      :order=>'created_at desc',:page => params[:page])
    @user_count=User.count(
      :conditions=>['(created_at>=? AND created_at<=?) AND (id=? OR email like ? OR username like ? OR given_name like ? OR identity_url like ? OR family_name like ? OR username like ?)',
        @start_date,
        @end_date,
      @user_search_string,
      search_string_parameter,
      search_string_parameter,
      search_string_parameter,
      search_string_parameter,
      search_string_parameter,
      search_string_parameter])
    
  end

  def export

    @user_search_string=params[:user_search_string] || ''
    search_string_parameter='%' + @user_search_string + '%' 
    @start_date=params[:start_date] || "2008-02-26"
    @end_date=params[:end_date] || Date.today.to_s(:db)
    
    @users=User.find(:all,
       :conditions=>['(created_at>=? AND created_at<=?) AND (id=? OR email like ? OR username like ? OR given_name like ? OR identity_url like ? OR family_name like ? OR username like ?)',
       @start_date,
       @end_date,
       @user_search_string,
       search_string_parameter,
        search_string_parameter,
        search_string_parameter,
        search_string_parameter,
        search_string_parameter,
        search_string_parameter],
       :order=>'created_at desc')
      report = StringIO.new
      CSV::Writer.generate(report, ',') do |title|
          title << ['Id', 'Username', 'Name', 'Email','Registered Date','Mailings?']
          @users.each do |u|
            title << [u.id,u.username,u.full_name,u.email,u.created_at.strftime("%m/%d/%y - %I:%M %p %Z"),u.mailing_list]       
          end
       end
       report.rewind
       send_data(report.read,:type=>'text/csv; charset=iso-8859-1; header=present',:filename => 'EOL_users_report_' + Time.now.strftime("%m_%d_%Y-%I%M%p") + '.csv', :disposition =>'attachment', :encoding => 'utf8')

  end
  
  def edit
    
    @user=User.find(params[:id])
    
  end
  
  def new  
    @user=User.create_new
  end
  
  def create
    
    @user=User.create_new(params[:user])
    @message=params[:message]

    Notifier.deliver_user_message(@user.full_name,@user.email,@message) unless @message.blank?
    
    @user.password=@user.entered_password
    params[:user][:role_ids] ||= []
    @user.set_curator(EOLConvert.to_boolean(params[:user][:curator_approved]),current_user)
    
    if @user.save
      flash[:notice]="The new user was created."
      redirect_to :action=>'index'
    else
      render :action=>'new'
    end
    
  end
  
  def update
  
   @user = User.find(params[:id])  
   @message=params[:message]

   Notifier.deliver_user_message(@user.full_name,@user.email,@message) unless @message.blank?
   
   @user.password=params[:user][:entered_password] unless params[:user][:entered_password].blank? && params[:user][:entered_password_confirmation].blank?
   @user.set_curator(EOLConvert.to_boolean(params[:user][:curator_approved]),current_user)
   
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
