# Handles non-admin curator functions, such as those performed by curators on individual species pages.
class CuratorsController < ApplicationController
  
  layout 'left_menu'

  access_control :DEFAULT => $CURATOR_ROLE_NAME
    
  before_filter :check_authentication
  before_filter :set_no_cache
  before_filter :set_layout_variables

  def index
  end

  def profile
    @user = User.find(current_user.id)
    @user.log_activity(:viewed_curator_profile)
    @user_submitted_text_count = UsersDataObject.count(:conditions=>['user_id = ?', params[:id]])
    redirect_back_or_default unless @user.curator_approved
  end

  # TODO - we need to link to this.  :)  There should be a hierarchy_entry_id provided, when we do.  We want each TC page to
  # have a link (for curators), using "an appropriate clade" for the hierarchy_entry_id.
  def curate_images
    current_user.log_activity(:viewed_images_to_curate)
    # TODO - This needs to add an optioanl argument to narrow by content partner.
    @images_to_curate = current_user.images_to_curate(
      :hierarchy_entry_id => params[:hierarchy_entry_id]
    ).paginate(:page => params[:page], :per_page => 5)
  end

  def curate_image
    @data_object = DataObject.find(params[:data_object_id])
    @data_object['attributions'] = @data_object.attributions
    @data_object['taxa_names_ids'] = [{'taxon_concept_id' => @data_object.hierarchy_entries[0].taxon_concept_id}]
    @data_object['media_type'] = @data_object.data_type.label
    current_user.log_activity(:showed_attributions_for_data_object_id, :value => @data_object.id)
    render :layout => false
  end

  def trust
    @data_object = DataObject.find(params[:data_object_id])
    @data_object.trust(current_user)
    @div_id = params[:div_id]
    respond_to do |fmt|
      fmt.js
    end
  end

  def untrust
    @data_object = DataObject.find(params[:data_object_id])
    @data_object.untrust(current_user)
    @div_id = params[:div_id]
    respond_to do |fmt|
      fmt.js
    end
  end

  def update_reasons
    puts "++ Got here"
    pp params
    @data_object = DataObject.find(params[:data_object_id])
    @data_object.untrust(current_user, params['untrust_reasons'])
    render :nothing => true
  end

  def show
    @data_object = DataObject.find(params[:data_object_id])
    @data_object.show(current_user)
    @div_id = params[:div_id]
    respond_to do |fmt|
      fmt.js
    end
  end

  def hide
    @data_object = DataObject.find(params[:data_object_id])
    @data_object.hide(current_user)
    @div_id = params[:div_id]
    respond_to do |fmt|
      fmt.js
    end
  end

  def remove
    @data_object = DataObject.find(params[:data_object_id])
    @data_object.inappropriate(current_user)
    @div_id = params[:div_id]
    respond_to do |fmt|
      fmt.js
    end
  end

  def comment
    @data_object = DataObject.find(params[:data_object_id])
    @data_object.comment(current_user, params['comment'])
    respond_to do |fmt|
      fmt.js { render :nothing => true }
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

end
