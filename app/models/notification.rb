# This is a user's notification settings, really.  Might have been a better name for this, in retrospect.
class Notification < ActiveRecord::Base
  belongs_to :user
  has_many :pending_notifications
  belongs_to :reply_to_comment, :foreign_key => :reply_to_comment,
    :class_name => 'NotificationFrequency'
  belongs_to :comment_on_my_profile, :foreign_key => :comment_on_my_profile,
    :class_name => 'NotificationFrequency'
  belongs_to :comment_on_my_contribution, :foreign_key => :comment_on_my_contribution,
    :class_name => 'NotificationFrequency'
  belongs_to :comment_on_my_collection, :foreign_key => :comment_on_my_collection,
    :class_name => 'NotificationFrequency'
  belongs_to :comment_on_my_community, :foreign_key => :comment_on_my_community,
    :class_name => 'NotificationFrequency'
  belongs_to :made_me_a_manager, :foreign_key => :made_me_a_manager,
    :class_name => 'NotificationFrequency'
  belongs_to :member_joined_my_community, :foreign_key => :member_joined_my_community,
    :class_name => 'NotificationFrequency'
  belongs_to :comment_on_my_watched_item, :foreign_key => :comment_on_my_watched_item,
    :class_name => 'NotificationFrequency'
  belongs_to :curation_on_my_watched_item, :foreign_key => :curation_on_my_watched_item,
    :class_name => 'NotificationFrequency'
  belongs_to :new_data_on_my_watched_item, :foreign_key => :new_data_on_my_watched_item,
    :class_name => 'NotificationFrequency'
  belongs_to :changes_to_my_watched_collection, :foreign_key => :changes_to_my_watched_collection,
    :class_name => 'NotificationFrequency'
  belongs_to :changes_to_my_watched_community, :foreign_key => :changes_to_my_watched_community,
    :class_name => 'NotificationFrequency'
  # This one is a misnomer.  It should be "member joined a community where I am a member." Sorry.
  belongs_to :member_joined_my_watched_community, :foreign_key => :member_joined_my_watched_community,
    :class_name => 'NotificationFrequency'
  belongs_to :member_left_my_community, :foreign_key => :member_left_my_community,
    :class_name => 'NotificationFrequency'
  belongs_to :new_manager_in_my_community, :foreign_key => :new_manager_in_my_community,
    :class_name => 'NotificationFrequency'
  belongs_to :i_am_being_watched, :foreign_key => :i_am_being_watched,
    :class_name => 'NotificationFrequency'

  validates_presence_of :user

  # NOTE - there's a relationship here to the PendingNotification class, which actually references the literal name of
  # the field.  THUS (!) if you create a new field on this table, note that you are limited to 64 characters or less.
  # I think that's a reasonable limit.  ;)
  
  def self.types_to_show_in_activity_feeds
    return [ :i_collected_something, :i_modified_a_community, :i_commented_on_something, :i_curated_something, :i_created_something ]
  end
  
  def self.queue_notifications(notification_recipient_objects, target)
    notification_queue = notification_recipient_objects.select {|o| self.acceptable_notifications(o, target) }
    notification_queue.each do |h|
      PendingNotification.create(:user => h[:user], :notification_frequency => h[:frequency], :target => target,
                                 :reason => h[:notification_type].to_s)
    end
    begin
      Resque.enqueue(PrepareAndSendNotifications) unless notification_queue.empty?
    rescue => e
      logger.error("** #queue_notifications ERROR: '#{e.message}'; ignoring...")
    end
    notification_queue
  end

  def self.acceptable_notifications(object, target)
    object.class == Hash && # Passed in something you shouldn't have.
      object[:user] && # Only users receive notifications.
      object[:user].class == User &&
      target.user_id != object[:user].id && # Users are never notified about their own action.
      object[:frequency] != NotificationFrequency.never && # User doesn't want any notification at all
      object[:frequency] != NotificationFrequency.newsfeed_only && # User doesn't want email for this
      ! object[:user].disable_email_notifications && # User doesn't want any email at all.
      ! (target.class == CuratorActivityLog && target.activity == Activity.crop) # We don't send emails about image crops.
  end
  
end
