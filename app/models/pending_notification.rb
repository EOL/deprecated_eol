class PendingNotification < ActiveRecord::Base
  belongs_to :user
  belongs_to :notification_frequency
  belongs_to :target, :polymorphic => true # For the record, these should ONLY be activity_loggable classes.
end
