class PendingNotification < ActiveRecord::Base
  belongs_to :user
  belongs_to :notification_frequency
  belongs_to :target, :polymorphic => true # For the record, these should ONLY be activity_loggable classes.

  named_scope :unsent, :conditions => {:sent_at => nil}
  named_scope :daily, lambda { {:conditions => ["notification_frequency_id = ?", NotificationFrequency.daily ] } }
  named_scope :immediately,
    lambda { {:conditions => ["notification_frequency_id = ?", NotificationFrequency.immediately ] } }
  named_scope :weekly, lambda { {:conditions => ["notification_frequency_id = ?", NotificationFrequency.weekly ] } }
  named_scope :by_user_id, lambda { |uid| {:conditions => ["user_id = ?", uid ] } }

  def self.send_notifications(fqz) # :immediately, :daily, :weekly are the only values allowed.
    notes_by_user_id = self.send(fqz).unsent.group_by(&:user_id)
    sent_note_ids = []
    notes_by_user_id.keys.each do |u_id|
      user = User.find(u_id, :select => 'id, email') rescue nil # Don't much care if the user disappeared.
      next unless user && user.email
      notes = notes_by_user_id[u_id]
      next unless notes
      begin
        RecentActivityMailer.deliver_recent_activity(user, notes.map(&:target).uniq, fqz)
      rescue => e
        if !@@delivered_error_notification || @@delivered_error_notification > 1.hour.ago
          RecentActivityMailer.deliver_notification_error(:user => user, :note_ids => notes.map(&:id),
                                                          :error => e.message, :frequency => fqz)
          @@delivered_error_notification = Time.now
        end
      ensure # Make SURE we don't re-send messages that have been sent:
        sent_note_ids += PendingNotification.mark_as_sent(notes.map(&:id))
      end
    end
    sent_note_ids.flatten.count # A semi-helpul return value.
  end

  # Bulk update cuts down on queries (and thus time):
  def self.mark_as_sent(sent_note_ids)
    unless sent_note_ids.empty?
      PendingNotification.connection.execute("UPDATE #{PendingNotification.table_name}
        SET sent_at=UTC_TIMESTAMP()
        WHERE id IN (#{sent_note_ids.flatten.join(', ')})")
    end
    return sent_note_ids # allows chaining and the like
  end

end
