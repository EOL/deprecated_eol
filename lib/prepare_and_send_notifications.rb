# NOTE #perform is for resque to pick it up, e.g.: Resque.enque(Periodically::Daily)
# Also, @queue must be a class variable with the Resque queue name to work in.
# Code taken (kinda) from http://railscasts.com/episodes/271-resque
module Periodically

  module Immediately

    @queue = :notifications

    def self.prepare_notifications
      [Comment, CuratorActivityLog, CollectionActivityLog, CommunityActivityLog, UsersDataObject].each do |klass|
        klass.notifications_not_prepared.each do |item|
          item.notify_listeners
          item.update_attribute(:notifications_prepared_at, Time.now) # no validations wanted, using #update_attribute
        end
      end
    end

    def self.perform
      Periodically::Immediately.prepare_notifications
      PendingNotification.send_notifications(:immediately)
    end

  end

  module Daily
    @queue = :notifications
    def self.perform
      PendingNotification.send_notifications(:daily)
    end
  end

  module Weekly
    @queue = :notifications
    def self.perform
      PendingNotification.send_notifications(:weekly)
    end
  end

end
