require 'net/http'
require 'uri'
class ResourcesController < ApplicationController

  # Opened for a malicious administrator who enters url by hand
  before_filter :agent_login_required, :resource_must_belong_to_agent, :agent_must_be_agreeable, :unless => :is_user_admin?

  layout 'content_partner'

  make_resourceful do

    actions :all, :except => :show

    response_for :create, :update do |format|
      format.html do
        @content_partner = ContentPartner.find(params[:content_partner_id])
        redirect_url = current_user.is_admin? ? { :controller => 'administrator/content_partner_report', :action => 'show', :id => @content_partner.agent.id} : resources_url
        redirect_to redirect_url
      end
    end

    # TODO - it is supremely LAME that we keep calling these things CPs when they are Agents.  It has bitten me twice in as
    # many days.  We should fix this.  Is the code *above* correct?  I don't know!  This is confusing.
    before :new do
      @content_partner = params[:content_partner_id] ? Agent.find(params[:content_partner_id]) : current_agent
    end

    before :edit do
      if params[:content_partner_id]
        @agent = Agent.find(params[:content_partner_id])
        @content_partner = @agent.content_partner
      end
      @page_header = 'Resources'
    end

    before :update do
      @original_resource = Resource.find(current_object.id)

      unless current_object.accesspoint_url.blank?
        current_object.dataset = nil
        current_object.dataset_file_name = nil
        current_object.dataset_content_type = nil
        current_object.dataset_file_size = nil
      end
    end

    after :create do
      current_object.accesspoint_url.strip! if current_object.accesspoint_url
      current_object.dwc_archive_url.strip! if current_object.dwc_archive_url
      resource_role = ResourceAgentRole.content_partner_upload_role
      # associate this uploaded resource with the current agent and the role of "data provider"
      # WEB-1223: sometimes SPG is getting a duplicate entry, which is... weird.  I'm trying to
      # avoid the second one being created.
      if AgentsResource.find_by_resource_id_and_resource_agent_role_id(current_object.id, resource_role.id)
        flash[:notice] = "Warning: you attempted to create a link from this resource to two agents. Only one allowed."[]
      else 
        AgentsResource.create(:resource_id => current_object.id,
                              :agent_id => current_agent.id,
                              :resource_agent_role_id => resource_role.id)
      end

      # call to file uploading web service 
      status = current_object.upload_resource_to_content_master('http://' + $IP_ADDRESS_OF_SERVER + ":" + request.port.to_s)
      current_object.resource_status = status

      current_object.save
    end

    after :update do
      current_object.accesspoint_url.strip! if current_object.accesspoint_url
      current_object.dwc_archive_url.strip! if current_object.dwc_archive_url
      unless current_object.accesspoint_url.blank?
        current_object.dataset = nil
        current_object.dataset_file_name = nil
        current_object.dataset_content_type = nil
        current_object.dataset_file_size = nil
        current_object.save
      end

      if current_user && current_user.is_admin?
        if params[:publish] == '1' and current_object.resource_status == ResourceStatus.processed
          current_object.resource_status = ResourceStatus.publish_pending
          flash[:notice] = "Resource is scheduled to be published"
        elsif params[:publish] == '0' and current_object.resource_status == ResourceStatus.published
          current_object.resource_status = ResourceStatus.unpublish_pending
          flash[:notice] = "Resource is scheduled to be unpublished"
        end

        if params[:auto_publish]=='1'
          current_object.auto_publish = 1 if current_object.auto_publish != 1
        else
          current_object.auto_publish = 0 if current_object.auto_publish != 0
        end

        if params[:vetted]=='1'
          current_object.set_vetted_status(1) if current_object.vetted != 1
        else
          current_object.set_vetted_status(0) if current_object.vetted != 0
        end
      end

      # only send the resource to the content server if it has been changed
      if @original_resource && (@original_resource.accesspoint_url != current_object.accesspoint_url || @original_resource.dataset_file_size != current_object.dataset_file_size)
        status = current_object.upload_resource_to_content_master('http://' + $IP_ADDRESS_OF_SERVER + ":" + request.port.to_s)
        current_object.resource_status = status
      end

      current_object.save
    end

    before :destroy do
      # delete the association between the resource and the agent if you delete the resource
      AgentsResource.find_all_by_resource_id(current_object.id).each {|agent_resource| agent_resource.destroy }
    end  

  end

  def invalid_resource
  end

  def force_harvest
    current_object.resource_status = ResourceStatus.force_harvest
    render :text => current_object.save ? current_object.status_label :
                                          '<span style="color:brown;">Force FAILED</span>'
  end

  #AJAX method to check for a valid URL
  def check_url
    params[:url].strip!
    if !params[:url].match(/\.xml(\.gz|\.gzip)?$/)
      message = 'File must be .xml or .xml.gz(ip)'
    elsif EOLWebService.url_accepted? params[:url]
      message = 'File was located successfully'
    else
      message = 'No file exists at this URL'
    end
    render :update do |page|
      page.replace_html 'url_warn', message
    end

  end

  def check_dwc_url 
    params[:url].strip!
    if !params[:url].match(/(\.tar\.(gz|gzip)|.tgz)/)
      message = 'DwC archive must be TARed and GZIPed'
    elsif EOLWebService.url_accepted? params[:url]
      message = 'DwC archive file found'
    else
      message = 'No file exists at this URL'
    end
    render :update do |page|
      page.replace_html 'dwc_url_warn', message
    end
  end

private

  def current_objects
    @current_objects ||= current_agent.resources
  end

end
