class PendingNotification < ActiveRecord::Base
  belongs_to :user
  belongs_to :notification_frequency
  belongs_to :target, :polymorphic => true # For the record, these should ONLY be activity_loggable classes.

  scope :unsent, :conditions => {:sent_at => nil}
  scope :daily, lambda { {:conditions => ["notification_frequency_id = ?", NotificationFrequency.daily ] } }
  scope :immediately,
    lambda { {:conditions => ["notification_frequency_id = ?", NotificationFrequency.immediately ] } }
  scope :weekly, lambda { {:conditions => ["notification_frequency_id = ?", NotificationFrequency.weekly ] } }
  scope :by_user_id, lambda { |uid| {:conditions => ["user_id = ?", uid ] } }

  def self.send_notifications(fqz) # :immediately, :daily, :weekly are the only values allowed.
    notes_by_user_id = self.send(fqz).unsent.group_by(&:user_id)
    sent_note_ids = []
    notes_by_user_id.keys.each do |u_id|
      user = User.find(u_id, :select => 'id, email') rescue nil # Don't much care if the user disappeared.
      next unless user && user.email
      notes = notes_by_user_id[u_id]
      next unless notes
      RecentActivityMailer.recent_activity(user, notes.map(&:target).uniq, fqz).deliver
      sent_note_ids += notes.map(&:id)
    end
    unless sent_note_ids.empty?
      # Bulk update cuts down on queries (and thus time):
      PendingNotification.connection.execute("UPDATE #{PendingNotification.table_name}
        SET sent_at=UTC_TIMESTAMP()
        WHERE id IN (#{sent_note_ids.flatten.join(', ')})")
    end
    sent_note_ids.flatten.count # A semi-helpul return value.
  end

end
