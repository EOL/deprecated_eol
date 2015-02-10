class ResourceValidation
  @queue = :resource_validation
  
  def self.perform(current_user_id, content_partner_id, resource_id, port)
    partner = ContentPartner.find(content_partner_id, include: {resources: :resource_status })
    resource = partner.resources.find(resource_id)
    user = User.find(current_user_id)
    resource.upload_resource_to_content_master!(port)    
    Notifier.user_message(user.username, user.email, I18n.t(:content_partner_resource_validation_finish_notice, resource_status: resource.status_label)).deliver       
  end
end