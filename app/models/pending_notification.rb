class PendingNotification < ActiveRecord::Base
  belongs_to :user
  belongs_to :notification_frequency
  belongs_to :target, :polymorphic => true # For the record, these should ONLY be activity_loggable classes.

  named_scope :unsent, :conditions => {:sent_at => nil}
  named_scope :after, lambda { |t| {:conditions => ["created_at > ?", t ] } } # TODO -needed?

end
