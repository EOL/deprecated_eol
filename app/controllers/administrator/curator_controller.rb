class Administrator::CuratorController < AdminController

  layout 'left_menu'

  before_filter :set_layout_variables

  access_control :web_users

  def index
    @page_title = I18n.t("curators")
    @user_search_string=params[:user_search_string] || ''
    search_string_parameter='%' + @user_search_string + '%'
    @only_unapproved=EOLConvert.to_boolean(params[:only_unapproved])

    only_unapproved_condition = ' curator_approved = 0 AND ' if @only_unapproved
    clade_condition = "credentials != '' OR curator_scope!= ''"

    condition="(#{clade_condition}) AND #{only_unapproved_condition} (email like ? OR username like ? OR given_name like ? OR identity_url like ? OR family_name like ? OR username like ?)"

    @users = User.paginate(:conditions => [condition, search_string_parameter], :order => 'curator_approved ASC, created_at DESC',:page => params[:page])
    @user_count = User.count(:conditions => [condition, search_string_parameter])
  end

  def export
    @users = User.find(:all, :conditions => ['credentials != "" OR curator_scope!= ""'])
      report = StringIO.new
      CSV::Writer.generate(report, ',') do |title|
          title << ['Id', 'Username', 'Name', 'Email', 'Credentials', 'Scope', 'Approved', 'Registered Date', 'Objects Curated', 'Comments Moderated',
                    'Species Curated', 'Objects Shown', 'Objects Hidden', 'Objects Marked as Inappropriate', 'Text Data Objects Submitted']
          @users.each do |u|
            title << [u.id, u.username, u.full_name, u.email, u.credentials.gsub(/\r\n/,'; '), u.curator_scope.gsub(/\r\n/,'; '), u.curator_approved,
                      u.created_at, u.total_data_objects_curated, u.total_comments_curated, u.total_species_curated, u.total_objects_curated_by_action('show'),
                      u.total_objects_curated_by_action('hide'), u.total_objects_curated_by_action('inappropriate'),
                      UsersDataObject.count(:conditions => ['user_id = ?', u.id])]
          end
       end
       report.rewind
       send_data(report.read, :type=>'text/csv; charset=iso-8859-1; header=present', :filename => 'EOL_curators_report_' + Time.now.strftime("%m_%d_%Y-%I%M%p") + '.csv',
        :disposition =>'attachment', :encoding => 'utf8')
  end

private

  def set_layout_variables
    @page_title = $ADMIN_CONSOLE_TITLE
    @navigation_partial = '/admin/navigation'
  end

end
