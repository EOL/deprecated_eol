require 'net/http'
require 'uri'
class ResourcesController < ApplicationController

  #Opened for a malicious administrator who enters url by hand
  before_filter :agent_login_required, :resource_must_belong_to_agent, :agent_must_be_agreeable, :unless => :is_user_admin?
  
  layout 'main'

  make_resourceful do

    actions :all , :except => :show

    response_for :create, :update do |format|
      format.html do 
        redirect_url = current_user.is_admin? ? { :controller => 'administrator/content_partner_report', :action => 'show', :id => params[:content_partner_id]} : resources_url
        redirect_to redirect_url
      end
    end

    after :create do
      
      resource_role=ResourceAgentRole.content_partner_upload_role
     # associate this uploaded resource with the current agent and the role of "data provider"
      AgentsResource.create(:resource_id=>current_object.id, :agent_id=>current_agent.id, :resource_agent_role_id=>resource_role.id)

      current_object.resource_status=ResourceStatus.uploaded if current_object.accesspoint_url.blank?
      
      # call to file uploading web service 
      file_path=(current_object.accesspoint_url.blank? ? 'http://' + $IP_ADDRESS_OF_SERVER + ":" + request.port.to_s + $DATASET_UPLOAD_PATH + current_object.id.to_s + "."+ current_object.dataset_file_name.split(".")[-1] : current_object.accesspoint_url)  
      parameters='function=upload_resource&resource_id=' + current_object.id.to_s + '&file_path=' + file_path
      response=EOLWebService.call(:parameters=>parameters)
      if response.blank?
        ErrorLog.create(:url  => $WEB_SERVICE_BASE_URL, :exception_name  => "content provider dataset service timed out") if $ERROR_LOGGING
        current_object.resource_status=ResourceStatus.upload_failed      
      else
        response = Hash.from_xml(response)
        if response["response"].key? "status"
          status = response["response"]["status"]
          current_object.resource_status=ResourceStatus.send(status.downcase.gsub(" ","_"))
          if response["response"].key? "error"
            error = response["response"]["error"]
            ErrorLog.create(:url=>$WEB_SERVICE_BASE_URL,:exception_name=>"content partner dataset service failed",:backtrace=>parameters) if $ERROR_LOGGING
            current_object.notes = error if status.strip == 'Validation failed'
          end          
        end
      end
      current_object.save
    end
    
    after :update do
      
      if current_user && current_user.is_admin?
        if params[:publish] == '1' and current_object.resource_status == ResourceStatus.processed
          if current_object.publish 
            flash[:notice] = "Resource is published"
          else
            flash[:error] = "Could not publish resource"
          end
        elsif params[:publish] == '0' and current_object.resource_status == ResourceStatus.published
          if current_object.unpublish 
            flash[:notice] = "Resource is unpublished"
          else
            flash[:error] = "Could not unpublish resource"
          end
        end
        current_object.auto_publish=params[:auto_publish] if params[:auto_publish]=='1' 
        current_object.set_vetted_status(params[:vetted]) if params[:vetted]=='1' 
      end

      current_object.save
      expire_taxa current_object.taxon_concept_ids, :expire_ancestors => true

    end

    before :destroy do
      
      # delete the association between the resource and the agent if you delete the resource
      AgentsResource.find_all_by_resource_id(current_object.id).each {|agent_resource| agent_resource.destroy }
      
    end  

  end

  def invalid_resource
  end
  
  #AJAX method to check for a valid URL
  def check_url    
    message = 'The supplied URL could not be located.' 
    message='The supplied URL was located successfully.' if EOLWebService.valid_url? params[:url]
    render :update do |page|
      page.replace_html 'url_warn', message
    end
    
  end
  
private
  def current_objects
    @current_objects ||= current_agent.resources
  end

end
