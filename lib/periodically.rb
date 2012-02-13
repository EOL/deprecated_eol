module Periodically

  module Immediately
    def self.prepare_notifications
      [Comment, CuratorActivityLog, CollectionActivityLog, CommunityActivityLog, UsersDataObject].each do |klass|
        klass.notifications_not_prepared.each do |item|
          item.notify_listeners
          item.update_attribute(:notifications_prepared_at, Time.now) # no validations wanted, using #update_attribute
        end
      end
    end
    def self.send_notifications
      PendingNotification.send_notifications(:immediately)
    end
  end

  module Daily
    def self.send_notifications
      PendingNotification.send_notifications(:daily)
    end
  end

  module Weekly
    def self.send_notifications
      PendingNotification.send_notifications(:weekly)
    end
  end

end
