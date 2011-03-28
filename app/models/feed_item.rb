class FeedItem < ActiveRecord::Base

  belongs_to :feed, :polymorphic => true
  belongs_to :subject, :polymorphic => true
  belongs_to :feed_item_type
  belongs_to :user

  validates_presence_of :feed_id
  validates_presence_of :feed_type
  validates_presence_of :body

  # DON'T pass in the polymorphic feed relationship; just pass in :feed.  DON'T pass in a user id; just pass in :user.
  def self.new_for(options = {})
    feed = nil
    if options.has_key? :feed
      feed = options.delete(:feed)
      options[:feed_type] = feed.class
      options[:feed_id] = feed.id
    else
      feed = case options[:feed_type]
      when TaxonConcept
        TaxonConcept.find(options[:feed_id])
      when DataObject
        DataObject.find(options[:feed_id])
      else
        nil
      end
    end
    added_by = options.delete(:user)
    options[:user_id] = added_by.id
    can_curate = added_by.can_curate? feed
    options[:feed_item_type_id] = can_curate ? FeedItemType.curator_comment.id : FeedItemType.user_comment.id
    self.new(options)
  end

end
