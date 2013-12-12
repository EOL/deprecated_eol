class Administrator::CuratorController < AdminController

  layout 'deprecated/left_menu'

  before_filter :set_layout_variables

  before_filter :restrict_to_admins

  require 'csv'

  def index
    @page_title = I18n.t("curators")
    @user_search_string = params[:user_search_string] || ''
    search_string_parameter = '%' + @user_search_string + '%'
    @only_unapproved = EOLConvert.to_boolean(params[:only_unapproved])
    @additional_javascript = ['application', 'admin-curator', 'temp']

    curator_level_ids = CuratorLevel.all.collect{ |c| c.id }.join(",")
    curator_condition = "(requested_curator_level_id IN (#{curator_level_ids}))"
    curator_condition += "OR (curator_level_id IN (#{curator_level_ids}))" unless @only_unapproved

    # We search six fields, so we need to pass six values.  TODO - this is likely silly and could be improved.
    condition = "#{curator_condition} AND (email like ? OR username like ? OR given_name like ? OR identity_url like ? OR family_name like ? OR username like ?)"
    conditions = [condition, search_string_parameter, search_string_parameter, search_string_parameter,
      search_string_parameter, search_string_parameter, search_string_parameter]

    @users = User.paginate(conditions: conditions, include: :curator_level, order: 'requested_curator_at DESC, curator_approved ASC',page: params[:page])
    @user_count = User.count(conditions: conditions)
  end

  def export
    user_curated_objects_counts = Curator.total_objects_curated_by_action_and_user(Activity.raw_curator_action_ids)
    user_curated_taxa_counts = Curator.taxon_concept_ids_curated
    user_comment_curations = Curator.comment_curation_actions
    user_show_counts = Curator.total_objects_curated_by_action_and_user(Activity.show.id)
    user_hide_counts = Curator.total_objects_curated_by_action_and_user(Activity.hide.id)
    user_submitted_counts = User.count_submitted_datos
    user_wikipedia_counts = User.count_user_rows(WikipediaQueue)
    user_association_counts = Curator.total_objects_curated_by_action_and_user(Activity.add_association.id, nil,
      [ChangeableObjectType.hierarchy_entry.id, ChangeableObjectType.curated_data_objects_hierarchy_entry.id])
    user_object_ratings = User.count_objects_rated
    user_exemplar_images = Curator.total_objects_curated_by_action_and_user(Activity.choose_exemplar_image.id)
    user_exemplar_text = Curator.total_objects_curated_by_action_and_user(Activity.choose_exemplar_article.id)
    user_preferred_classifications = Curator.total_objects_curated_by_action_and_user(Activity.preferred_classification.id, nil, [ChangeableObjectType.curated_taxon_concept_preferred_entry.id])
    user_common_names_added = Curator.total_objects_curated_by_action_and_user(Activity.add_common_name.id, nil, [ChangeableObjectType.synonym.id])
    user_common_names_curated = Curator.total_objects_curated_by_action_and_user([Activity.trust_common_name.id, Activity.untrust_common_name.id, Activity.unreview_common_name.id, Activity.inappropriate_common_name.id], nil, [ChangeableObjectType.synonym.id])
    user_comments_added = User.count_comments_added
    
    @users = User.find(:all, include: :curator_level, conditions: ['curator_level_id > 0'])
    report = StringIO.new
    csv = CSV.generate(col_sep: "\t") do |line|
        line << ['Id', 'Username', 'Name', 'Email', 'Credentials', 'Scope', 'Approved', 'Curator Level', 'Registered Date', 'Objects Curated',
                  'Comments Moderated', 'Species Curated', 'Objects Shown', 'Objects Hidden',
                  'Text Data Objects Submitted', 'Associations Added', 'Wikipedia Articles Nominated', 'Objects Rated', 'Exemplar Images Set',
                  'Overview Articles Set', 'Classifications Preferred', 'Common Names Added', 'Common Names Curated', 'Comments Added']
        @users.each do |u|
          comments_curated = user_comment_curations[u.id].length rescue 0
          taxa_curated = user_curated_taxa_counts[u.id].length rescue 0
          user_credentials = u.credentials.gsub(/[\r\n\t]/,'; ')[0...5000]
          user_scope = u.curator_scope.gsub(/[\r\n\t]/,'; ')[0...5000]
          line << [u.id, u.username, u.full_name, u.email, user_credentials, user_scope, u.curator_approved, u.curator_level.translated_label,
                    u.created_at, user_curated_objects_counts[u.id] || 0, comments_curated, taxa_curated, user_show_counts[u.id] || 0,
                    user_hide_counts[u.id] || 0, user_submitted_counts[u.id] || 0,
                    user_association_counts[u.id] || 0, user_wikipedia_counts[u.id] || 0, user_object_ratings[u.id] || 0,
                    user_exemplar_images[u.id] || 0, user_exemplar_text[u.id] || 0, user_preferred_classifications[u.id] || 0,
                    user_common_names_added[u.id] || 0, user_common_names_curated[u.id] || 0, user_comments_added[u.id] || 0]
        end
     end
     
     send_data csv,
       type: 'text/tab-separated-values; charset=utf-8; header=present',
       filename: 'EOL_curators_report_' + Time.now.strftime("%m_%d_%Y-%I%M%p") + '.txt',
       encoding: 'utf8',
       disposition: "attachment"
  end

private

  def set_layout_variables
    @page_title = $ADMIN_CONSOLE_TITLE
    @navigation_partial = '/admin/navigation'
  end

end
