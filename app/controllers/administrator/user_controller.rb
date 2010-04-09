class Administrator::UserController  < AdminController

  access_control :DEFAULT => 'Administrator - Web Users'
  layout 'admin'

  def index

    @page_title = 'Web Users'
    
    @user_search_string=params[:user_search_string] || ''
    search_string_parameter='%' + @user_search_string + '%' 
    @start_date=params[:start_date] || "2008-02-28"
    @end_date=params[:end_date] || Date.today.to_s(:db)
    @blank_dates=EOLConvert.to_boolean(params[:blank_dates])
    export=params[:export]
    
    begin
      @start_date_db=(Date.parse(@start_date)).to_s(:db)
      @end_date_db=(Date.parse(@end_date)+1).to_s(:db)
    rescue
    end
    
    blank_date_condition=' OR (created_at is null)' unless @blank_dates
    
    condition="((created_at>=? AND created_at<=?) #{blank_date_condition}) AND (id=? OR email like ? OR username like ? OR given_name like ? OR identity_url like ? OR family_name like ? OR username like ?)"
        
    if export
      @users=User.find(:all,
        :conditions=>[condition,
        @start_date_db,
        @end_date_db,
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
          title << ['Id', 'Username', 'Name', 'Email','Registered Date','Mailings?','OpenID?']
          @users.each do |u|
            created_at=''
            created_at=u.created_at.strftime("%m/%d/%y - %I:%M %p %Z") unless u.created_at.blank?
            title << [u.id,u.username,u.full_name,u.email,created_at,u.mailing_list,u.openid?]       
          end
       end
       report.rewind
       send_data(report.read,:type=>'text/csv; charset=iso-8859-1; header=present',:filename => 'EOL_users_report_' + Time.now.strftime("%m_%d_%Y-%I%M%p") + '.csv', :disposition =>'attachment', :encoding => 'utf8')
       return false
    end

    @users=User.paginate(
      :conditions=>[condition,
      @start_date_db,
      @end_date_db,
      @user_search_string,
      search_string_parameter,
       search_string_parameter,
       search_string_parameter,
       search_string_parameter,
       search_string_parameter,
       search_string_parameter],
      :order=>'created_at desc',:page => params[:page])

      
    @user_count=User.count(
      :conditions=>[condition,
        @start_date_db,
        @end_date_db,
      @user_search_string,
      search_string_parameter,
      search_string_parameter,
      search_string_parameter,
      search_string_parameter,
      search_string_parameter,
      search_string_parameter])
    
  end
  
  def edit
    store_location(referred_url) if request.get?    
    @user=User.find(params[:id])
    @page_title = "Edit #{@user.username}"
  end
  
  def new  
    @page_title = 'New User'
    store_location(referred_url) if request.get?
    @user=User.create_new
  end
  
  def create
    
    @user=User.create_new(params[:user])
    @message=params[:message]

    Notifier.deliver_user_message(@user.full_name,@user.email,@message) unless @message.blank?
    
    @user.password=@user.entered_password
    params[:user][:role_ids] ||= []
    
    if @user.save
      @user.set_curator(EOLConvert.to_boolean(params[:user][:curator_approved]),current_user)
      flash[:notice]="The new user was created."
      redirect_back_or_default(url_for(:action=>'index'))
    else
      render :action=>'new'
    end
    
  end
  
  def update
  
   @user = User.find(params[:id])  
   @message=params[:message]
  
   Notifier.deliver_user_message(@user.full_name,@user.email,@message) unless @message.blank?
  
   user_params=params[:user]
       
   unless user_params[:entered_password].blank? && user_params[:entered_password_confirmation].blank?
      if user_params[:entered_password].length < 4 || user_params[:entered_password].length > 16
         @user.errors.add_to_base("Password length must be between 4 and 16 characters."[:password_must_be_4to16_characters])
         render :action=>'edit'
         return
     end
     @user.password=user_params[:entered_password]
   end
   
   if @user.update_attributes(user_params)
      if params[:curator_denied]
        @user.clear_curatorship(current_user)
      else
        @user.set_curator(EOLConvert.to_boolean(user_params[:curator_approved]),current_user)
      end
      flash[:notice]="The user was updated."
      redirect_back_or_default(url_for(:action=>'index'))
    else
      render :action=>'edit'
    end
  end
  

 def destroy

   (redirect_to referred_url ;return) unless request.method == :delete
   
   user = User.find(params[:id])
   user.destroy

   redirect_to referred_url 
   
 end
 
  def toggle_curator
    
    @user = User.find(params[:id])
    @user.set_curator(!params[:curator_approved].nil?,current_user)
    @user.save!
  
  end

  def clear_curatorship
    user = User.find(params[:id])
    user.clear_curatorship(current_user,params[:notes])
    user.save!
  end
  
  def login_as_user

      user=User.find_by_id(params[:id])   

      if !user.blank?
        reset_session
        set_current_user(user)
        flash[:message]="You have been logged in as #{@user.username}"
        redirect_to root_url
      end
      return
      
  end  
  
end
