# Handles non-admin curator functions, such as those performed by curators on individual species pages.
class CuratorsController < ApplicationController

  layout 'left_menu'

  access_control :vet

  before_filter :check_authentication
  before_filter :set_no_cache
  before_filter :set_layout_variables

  def index
    get_page_content
  end

  def profile
    @user = params[:id].nil? ? User.find(current_user.id) : User.find(params[:id])
    @user.log_activity(:viewed_curator_profile)
    @user_submitted_text_count = UsersDataObject.count(:conditions=>['user_id = ?', params[:id]])
    redirect_back_or_default unless @user.curator_approved
  end

  # TODO - we need to link to this.  :)  There should be a hierarchy_entry_id provided, when we do.  We want each TC page to
  # have a link (for curators), using "an appropriate clade" for the hierarchy_entry_id.
  def curate_images
    @page_title += ": " + I18n.t("curate_images")
    published_resources
    session['curate_images_hierarchy_entry_id'] = params['hierarchy_entry_id'] if params['hierarchy_entry_id']
    session['curate_images_hierarchy_entry_id'] = nil if session['curate_images_hierarchy_entry_id'].blank?
    @content_partner = params[:content_partner_id] ? ContentPartner.find(params[:content_partner_id]) : nil
    @status = params[:vetted_id].blank? ? '' : ((params[:vetted_id] == 'all') ? "all" : Vetted.find_by_id(params[:vetted_id]).label)
    @name = params['hierarchy_entry_id'].blank? ? '' : Name.find_by_id(HierarchyEntry.find_by_id(params['hierarchy_entry_id'], :select => 'name_id').name_id)
    current_user.log_activity(:viewed_images_to_curate)
    all_images = current_user.images_to_curate(
      :content_partner_id => params[:content_partner_id],
      :vetted_id => params[:vetted_id],
      :hierarchy_entry_id => session['curate_images_hierarchy_entry_id'],
      :page => params[:page], :per_page => 30)
    @all_images_count = all_images.count
    @images_to_curate = all_images.paginate(:page => params[:page], :per_page => 30)
  end

  def curate_image
    @data_object = DataObject.find(params[:data_object_id])
    current_user.log_activity(:showed_attributions_for_data_object_id, :value => @data_object.id)
    render :layout => false
  end

  # def ignored_images
  #   @page_title += ": " + I18n.t("ignored_images_")
  #   session['ignored_images_hierarchy_entry_id'] = params['hierarchy_entry_id'] if params['hierarchy_entry_id']
  #   session['ignored_images_hierarchy_entry_id'] = nil if session['ignored_images_hierarchy_entry_id'].blank?
  #   @name = params['hierarchy_entry_id'].blank? ? '' : Name.find_by_id(HierarchyEntry.find_by_id(params['hierarchy_entry_id'], :select => 'name_id').name_id)
  #   all_images = current_user.ignored_data_objects(
  #     :hierarchy_entry_id => session['ignored_images_hierarchy_entry_id'], 
  #     :data_type_id => DataType.image.id)
  #   @ignored_images = all_images
  # end

  def comment
    @data_object = DataObject.find(params[:data_object_id])
    @data_object.comment(current_user, params['comment'])
    respond_to do |format|
      format.js do 
        comments = @data_object.all_comments.select(&:visible?)
        current_user_comments = comments.select { |c| c.user.id == current_user.id && c.visible? }
        render :json => { :last_comment => params['comment'].balance_tags, :comments => comments.size, :current_user_comments => current_user_comments.size, :data_object_id => params[:data_object_id] }
      end
      format.html { redirect_to(:controller => :curators, :action => :curate_images, :anchor => "curation-item-#{params[:data_object_id]}", :hierarchy_entry_id => params['hierarchy_entry_id']) }
    end
  end

private

  def set_no_cache
    @no_cache=true
  end

  def set_layout_variables
    @additional_stylesheet = 'curator_tools'
    @page_title = $CURATOR_CENTRAL_TITLE
    @navigation_partial = '/curators/navigation'
  end
  
  def published_resources
    @published_resources = ContentPartner.with_published_data.collect{ |cp| [ cp.user.full_name, cp.id ] }.sort_by{ |arr| arr[0].downcase }
  end
  
  def get_page_content
    params[:id] = params[:id].nil? ? "curator_central" : params[:id]
    @content = ContentPage.smart_find_with_language(params[:id], current_user.language_abbr)
    @page_title += ": #{@content.title}" unless params[:id] == "curator_central"
  end
  
end
