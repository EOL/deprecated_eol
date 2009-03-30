class Administrator::UserController  < AdminController

  access_control :DEFAULT => 'Administrator - Web Users'

  def index
    
    @user_search_string=params[:user_search_string] || ''
    search_string_parameter='%' + @user_search_string + '%' 
    @start_date=params[:start_date] || "2009-01-05"
    @end_date=params[:end_date] || Date.today.to_s(:db)
    @blank_dates=EOLConvert.to_boolean(params[:blank_dates])
    export=params[:export]
    
    begin
      @start_date_db=(Date.parse(@start_date)).to_s(:db)
      @end_date_db=(Date.parse(@end_date)+1).to_s(:db)
    rescue
    end
    
    blank_date_condition=' OR (created_at is null)' if @blank_dates
    
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
