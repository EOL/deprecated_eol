# NOTE #perform is for resque to pick it up, e.g.: Resque.enque(PrepareAndSendNotifications)
# Also, @queue must be a class variable with the Resque queue name to work in.
# Code taken (kinda) from http://railscasts.com/episodes/271-resque
class PrepareAndSendNotifications
  @queue = 'notifications'

  class << self
    def perform
      EOL.log_call
      Comment.with_master do
        PendingNotification.send_notifications(:immediately)

        if (NotificationEmailerSettings.last_daily_emails_sent + 24.hours) < Time.now
          EOL.log("Sending daily mail.")
          PendingNotification.send_notifications(:daily)
          NotificationEmailerSettings.last_daily_emails_sent = Time.now
        end

        if (NotificationEmailerSettings.last_weekly_emails_sent + 1.week) < Time.now
          EOL.log("Sending weekly mail.")
          PendingNotification.send_notifications(:weekly)
          NotificationEmailerSettings.last_weekly_emails_sent = Time.now
        end
      end
      EOL.log_return
    end

    def enqueue
      Resque.enqueue(PrepareAndSendNotifications) unless pending?
    end

    def pending?
      begin
        Resque.peek(:notifications, 0, 25_000).
                 any? { |j| j["class"] == "PrepareAndSendNotifications" }
      rescue => e
        EOL.log("WARNING: Failed to read 'notifications' queue: #{e.message}",
          prefix: "!")
        false
      end
    end
  end
end
