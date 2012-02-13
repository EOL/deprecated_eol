class Periodically

  class Often

    def self.prepare_notifications
      classes_with_notifications =
        [Comments, CuratorActivityLog, CollectionActivityLog, CommunityActivityLog, UsersDataObject]
      classes_with_notifications.each do |klass|
        klass.all.notification_not_prepared.each do |c|
          c.notify_listeners
          c.update_attribute(:notifications_prepared, true) # No validations; don't care.
        end
      end
    end

    def self.send_notification_emails
      PendingNotifications.unsent.daily.group_by(&:user_id).keys.each do |user_id|
        Notifier.deliver_recent_activity(User.find(user_id, :select => 'email'), by_user[user_id])
      end
    end

  end

  class Daily

    def self.send_notification_emails
      PendingNotifications.unsent.daily.group_by(&:user_id).keys.each do |user_id|
        Notifier.deliver_recent_activity(User.find(user_id, :select => 'email'), by_user[user_id])
      end
    end

  end

end
