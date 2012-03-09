# NOTE #perform is for resque to pick it up, e.g.: Resque.enque(PrepareAndSendNotifications)
# Also, @queue must be a class variable with the Resque queue name to work in.
# Code taken (kinda) from http://railscasts.com/episodes/271-resque
class PrepareAndSendNotifications
  @queue = :notifications

  def self.perform
    PendingNotification.send_notifications(:immediately)
  end

  # TODO - these will be handled later... I need to figure them out.

  class Daily
    @queue = :notifications
    def self.perform
      PendingNotification.send_notifications(:daily)
    end
  end

  class Weekly
    @queue = :notifications
    def self.perform
      PendingNotification.send_notifications(:weekly)
    end
  end

end
