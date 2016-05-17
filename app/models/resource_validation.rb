class ResourceValidation
  @queue = "data"

  class << self
    def perform(user_id, resource_id, loc)
      EOL.log_call
      resource = Resource.find(resource_id)
      EOL.log("Resource: ##{resource_id} #{resource.title}", prefix: ".")
      EOL.log("User ID: ##{user_id}", prefix: ".")
      EOL.log("Location: #{loc}", prefix: ".")
      resource.upload_resource_to_content_master(loc)
      write_log_send_mail(user_id, resource_id)
      EOL.log_return
    end

    def write_log_send_mail(user_id, resource_id)
      log = CuratorActivityLog.create!(
        user_id: user_id,
        changeable_object_type_id: ChangeableObjectType.resource_validation.id,
        target_id: resource_id,
        activity: Activity.resource_validation
      )
      PendingNotification.create!(
        user_id: user_id,
        notification_frequency_id: NotificationFrequency.immediately.id,
        target: log,
        reason: 'auto_email_after_validation'
      )
      PrepareAndSendNotifications.enqueue
    end
  end
end
