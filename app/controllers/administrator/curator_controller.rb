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

  def export

    @users=User.find(:all,:conditions=>['curator_hierarchy_entry_id IS NOT NULL'])
      report = StringIO.new
      CSV::Writer.generate(report, ',') do |title|
          title << ['Id', 'Username', 'Name', 'Email', 'Credentials','Clade','Approved','Date']
          @users.each do |u|
            title << [u.id,u.username,u.full_name,u.email,u.credentials,u.curator_hierarchy_entry.name,u.curator_approved,u.created_at.strftime("%m/%d/%y - %I:%M %p %Z")]       
          end
       end
       report.rewind
       send_data(report.read,:type=>'text/csv; charset=iso-8859-1; header=present',:filename => 'EOL_curators_report_' + Time.now.strftime("%m_%d_%Y-%I%M%p") + '.csv', :disposition =>'attachment', :encoding => 'utf8')

  end
  
end
