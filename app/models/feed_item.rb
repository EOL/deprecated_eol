class FeedItem < ActiveRecord::Base

  belongs_to :feed, :polymorphic => true
  belongs_to :subject, :polymorphic => true

  validates_presence_of :feed_id
  validates_presence_of :feed_type
  validates_presence_of :body

end
