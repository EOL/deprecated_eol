require 'net/http'
require 'uri'
class ResourcesController < ApplicationController
  before_filter :check_authentication
  layout 'user_profile'
  
  make_resourceful do

    actions :all, :except => :show

    response_for :create, :update do |format|
      format.html do
        @content_partner = params[:content_partner_id] ? ContentPartner.find(params[:content_partner_id]) : current_user.content_partner
        redirect_url = current_user.is_admin? ? { :controller => 'administrator/content_partner_report', :action => 'show', :id => @content_partner.agent.id} : resources_url
        redirect_to redirect_url
      end
    end
    
    before :create do
      current_object.content_partner_id = current_user.content_partner.id
    end

    before :new do
      @content_partner = params[:content_partner_id] ? ContentPartner.find(params[:content_partner_id]) : current_user.content_partner
    end

    before :edit do
      @content_partner = params[:content_partner_id] ? ContentPartner.find(params[:content_partner_id]) : current_user.content_partner
      @page_header = 'Resources'
    end

    before :update do
      Resource.with_master do
        @original_resource = Resource.find(current_object.id)
      end
      
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
          flash[:notice] = I18n.t("resource_is_scheduled_to_be_pu")
        elsif params[:publish] == '0' and current_object.resource_status == ResourceStatus.published
          current_object.resource_status = ResourceStatus.unpublish_pending
          flash[:notice] = I18n.t("resource_is_scheduled_to_be_un")
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

  def current_object
    # we always want to read the latest resources from the master database
    # to avoid replication lag problems
    if params[:id]
      @current_object ||= Resource.with_master do
        Resource.find(params[:id])
      end
    end
    return @current_object
  end

  def current_objects
    # we always want to read the latest resources from the master database
    # to avoid replication lag problems
    @current_objects ||= Resource.with_master do
      content_partner = params[:content_partner_id] ? ContentPartner.find(params[:content_partner_id]) : current_user.content_partner
      content_partner.resources.clone
    end
    return @current_objects
  end

end
