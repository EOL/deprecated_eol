class ContentPartners::Resources::HierarchiesController < ContentPartners::ResourcesController

  before_filter :check_authentication
  before_filter :restrict_to_admins, :except => [:request_publish]

  # GET /content_partners/:content_partner_id/resources/:resource_id/hierarchies/:id/edit
  def edit
    @hierarchy = Hierarchy.find(params[:id], :include => { :resource => :content_partner } )
    @partner = @hierarchy.resource.content_partner
    @resource = @hierarchy.resource
    access_denied unless current_user.is_admin? && @resource.id == params[:resource_id].to_i &&
                         @partner.id == params[:content_partner_id].to_i
    @page_subheader = I18n.t(:content_partner_resource_hierarchy_edit_subheader, :resource_title => @resource.title)
    params[:return_to] ||= content_partner_resource_path(@partner, @resource)
  end

  # PUT /content_partners/:content_partner_id/resources/:resource_id/hierarchies/:id
  def update
    @hierarchy = Hierarchy.find(params[:id], :include => { :resource => :content_partner } )
    @partner = @hierarchy.resource.content_partner
    @resource = @hierarchy.resource
    access_denied unless current_user.is_admin? && @resource.id == params[:resource_id].to_i &&
                         @partner.id == params[:content_partner_id].to_i
    if @hierarchy.update_attributes(params[:hierarchy])
      Rails.cache.delete('hierarchies/browsable_by_label')
      Hierarchy.delete_cached('id', @hierarchy.id)
      flash[:notice] = I18n.t(:content_partner_resource_hierarchy_update_successful_notice)
      store_location params[:return_to]
      redirect_back_or_default content_partner_resource_path(@partner, @resource)
    else
      flash.now[:error] = I18n.t(:content_partner_resource_hierarchy_update_unsuccessful_error)
      @page_subheader = I18n.t(:content_partner_resource_hierarchy_edit_subheader, :resource_title => @resource.title)
      render :edit
    end

  end

  # POST /content_partners/:content_partner_id/resources/:resource_id/hierarchies/:id/request_publish
  def request_publish
    @hierarchy = Hierarchy.find(params[:id], :include => { :resource => :content_partner } )
    @partner = @hierarchy.resource.content_partner
    @resource = @hierarchy.resource
    access_denied unless @resource.id == params[:resource_id].to_i && current_user.can_update?(@resource) &&
                         @partner.id == params[:content_partner_id].to_i && request.post?
    if @hierarchy.request_to_publish_can_be_made? && @hierarchy.update_attributes(:request_publish => true)
      Hierarchy.delete_cached('id', @hierarchy.id)
      flash[:notice] = I18n.t(:content_partner_resource_hierarchy_update_successful_notice)
      Notifier.deliver_content_partner_resource_hierarchy_publish_request(@partner, @resource, @hierarchy, current_user)
    else
      flash[:error] = I18n.t(:content_partner_resource_hierarchy_update_unsuccessful_error)
    end
    store_location params[:return_to] unless params[:return_to].blank?
    redirect_back_or_default content_partner_resource_path(@partner, @resource)
  end
end
