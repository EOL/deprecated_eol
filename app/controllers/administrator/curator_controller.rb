class Administrator::CuratorController < AdminController

  access_control :DEFAULT => 'Administrator - Web Users'
    
  def index
    @user_search_string=params[:user_search_string] || ''
    search_string_parameter='%' + @user_search_string + '%' 
    @only_unapproved=EOLConvert.to_boolean(params[:only_unapproved])
    @only_without_clade=EOLConvert.to_boolean(params[:only_without_clade])

    only_unapproved_condition=' curator_approved = 0 AND ' if @only_unapproved
    if @only_without_clade
       clade_condition="curator_hierarchy_entry_id IS NULL AND (credentials <> '' OR curator_scope<> '')"
    else
      clade_condition="curator_hierarchy_entry_id IS NOT NULL OR credentials <> '' OR curator_scope<> ''"     
    end
    
    condition="(#{clade_condition}) AND #{only_unapproved_condition} (email like ? OR username like ? OR given_name like ? OR identity_url like ? OR family_name like ? OR username like ?)"

    @users=User.paginate(
                         :conditions=>[condition,
    search_string_parameter,
    search_string_parameter,
    search_string_parameter,
    search_string_parameter,
    search_string_parameter,
    search_string_parameter],
    :order=>'curator_approved ASC, created_at DESC',:page => params[:page])
    @user_count=User.count(
                           :conditions=>[condition,
    search_string_parameter,
    search_string_parameter,
    search_string_parameter,
    search_string_parameter,
    search_string_parameter,
    search_string_parameter])
    
  end

  def export

    @users=User.find(:all,:conditions=>['curator_hierarchy_entry_id IS NOT NULL OR credentials <> "" OR curator_scope<> ""'])
      report = StringIO.new
      CSV::Writer.generate(report, ',') do |title|
          title << ['Id', 'Username', 'Name', 'Email', 'Credentials','Scope','Clade','Approved','Registered Date','Objects Curated','Comments Moderated','Species Curated','Text Data Objects Submitted']
          @users.each do |u|
            clade_name = u.curator_hierarchy_entry.nil? ? '' : u.curator_hierarchy_entry.name
            title << [u.id,u.username,u.full_name,u.email,u.credentials.gsub(/\r\n/,'; '),u.curator_scope.gsub(/\r\n/,'; '),clade_name,u.curator_approved,u.created_at,u.total_objects_curated,u.total_comments_curated,u.total_species_curated,UsersDataObject.count(:conditions=>['user_id = ?',u.id])]       
          end
       end
       report.rewind
       send_data(report.read,:type=>'text/csv; charset=iso-8859-1; header=present',:filename => 'EOL_curators_report_' + Time.now.strftime("%m_%d_%Y-%I%M%p") + '.csv', :disposition =>'attachment', :encoding => 'utf8')

  end
  
end
