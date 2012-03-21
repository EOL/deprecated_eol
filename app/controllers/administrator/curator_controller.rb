class Administrator::CuratorController < AdminController

  layout 'left_menu'

  before_filter :set_layout_variables

  before_filter :restrict_to_admins

  require 'csv'
  
  def index
    @page_title = I18n.t("curators")
    @user_search_string = params[:user_search_string] || ''
    search_string_parameter = '%' + @user_search_string + '%'
    @only_unapproved = EOLConvert.to_boolean(params[:only_unapproved])
    @additional_javascript = ['application', 'admin-curator', 'temp']

    only_unapproved_condition = ' curator_approved = 0 AND ' if @only_unapproved
    
    curator_level_ids = CuratorLevel.all.collect{ |c| c.id }.join(",")
    if_curator = "(curator_level_id IN (#{curator_level_ids}))"
    requested_curatorship = "(requested_curator_level_id IN (#{curator_level_ids}))"

    # We search six fields, so we need to pass six values.  TODO - this is likely silly and could be improved.
    condition = "(#{if_curator} OR #{requested_curatorship}) AND #{only_unapproved_condition} (email like ? OR username like ? OR given_name like ? OR identity_url like ? OR family_name like ? OR username like ?)"
    conditions = [condition, search_string_parameter, search_string_parameter, search_string_parameter,
      search_string_parameter, search_string_parameter, search_string_parameter]

    @users = User.paginate(:conditions => conditions, :include => :curator_level, :order => 'requested_curator_at DESC, curator_approved ASC',:page => params[:page])
    @user_count = User.count(:conditions => conditions)
  end

  def export
    user_curated_objects_counts = User.total_objects_curated_by_action_and_user(Activity.raw_curator_action_ids)
    user_curated_taxa_counts = User.taxon_concept_ids_curated
    user_comment_curations = User.comment_curation_actions
    user_show_counts = User.total_objects_curated_by_action_and_user(Activity.show.id)
    user_hide_counts = User.total_objects_curated_by_action_and_user(Activity.hide.id)
    user_inappropriate_counts = User.total_objects_curated_by_action_and_user(Activity.inappropriate.id)
    user_submitted_counts = User.count_submitted_datos
    user_wikipedia_counts = User.count_user_rows(WikipediaQueue)
    user_association_counts = User.total_objects_curated_by_action_and_user(Activity.add_association.id, nil,
      [ChangeableObjectType.hierarchy_entry.id, ChangeableObjectType.curated_data_objects_hierarchy_entry.id])
    
    @users = User.find(:all, :include => :curator_level, :conditions => ['curator_level_id > 0'])
    report = StringIO.new
    CSV::Writer.generate(report, '	') do |title|
        title << ['Id', 'Username', 'Name', 'Email', 'Credentials', 'Scope', 'Approved', 'Curator Level', 'Registered Date', 'Objects Curated',
                  'Comments Moderated', 'Species Curated', 'Objects Shown', 'Objects Hidden', 'Objects Marked as Inappropriate',
                  'Text Data Objects Submitted', 'Associations Added', 'Wikipedia Articles Nominated']
        @users.each do |u|
          comments_curated = user_comment_curations[u.id].length rescue 0
          taxa_curated = user_curated_taxa_counts[u.id].length rescue 0
          user_credentials = u.credentials.gsub(/[\r\n\t]/,'; ')[0...5000]
          user_scope = u.curator_scope.gsub(/[\r\n\t]/,'; ')[0...5000]
          title << [u.id, u.username, u.full_name, u.email, user_credentials, user_scope, u.curator_approved, u.curator_level.label,
                    u.created_at, user_curated_objects_counts[u.id] || 0, comments_curated, taxa_curated, user_show_counts[u.id] || 0,
                    user_hide_counts[u.id] || 0, user_inappropriate_counts[u.id] || 0, user_submitted_counts[u.id] || 0,
                    user_association_counts[u.id] || 0, user_wikipedia_counts[u.id] || 0 ]
        end
     end
     report.rewind
     send_data(report.read, :type=>'text/tab-separated-values; charset=utf-8; header=present',
       :filename => 'EOL_curators_report_' + Time.now.strftime("%m_%d_%Y-%I%M%p") + '.txt',
       :disposition =>'attachment', :encoding => 'utf8')
  end

private

  def set_layout_variables
    @page_title = $ADMIN_CONSOLE_TITLE
    @navigation_partial = '/admin/navigation'
  end

end
