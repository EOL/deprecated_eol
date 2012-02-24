class PendingNotification < ActiveRecord::Base
  belongs_to :user
  belongs_to :notification_frequency
  belongs_to :target, :polymorphic => true # For the record, these should ONLY be activity_loggable classes.

  named_scope :unsent, :conditions => {:sent_at => nil}
  named_scope :daily, lambda { {:conditions => ["notification_frequency_id = ?", NotificationFrequency.daily ] } }
  named_scope :immediately,
    lambda { {:conditions => ["notification_frequency_id = ?", NotificationFrequency.immediately ] } }
  named_scope :weekly, lambda { {:conditions => ["notification_frequency_id = ?", NotificationFrequency.weekly ] } }

  def self.send_notifications(fqz)
    notes_by_user_id = self.send(fqz).unsent.group_by(&:user_id)
    notes_by_user_id.keys.each do |u_id|
      user = User.find(u_id, :select => 'id, email') rescue nil # Don't much care if the user disappeared.
      next unless user
      notes = notes_by_user_id[u_id]
      next unless notes
      Notifier.deliver_recent_activity(user, notes.map(&:target).uniq)
      notes.each {|note| note.update_attribute(:sent_at, Time.now)} # Skips validations w/ _attribute
    end
  end

end
