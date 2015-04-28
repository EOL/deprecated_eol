class AddCurationAndCommentsOnNotificationsToContentPartners < ActiveRecord::Migration
  def change
    add_column :notifications, :comment_on_my_content_partner_data , :integer, default: NotificationFrequency.immediately.id
    add_column :notifications, :curation_on_my_content_partner_data , :integer, default: NotificationFrequency.immediately.id
  end
end
