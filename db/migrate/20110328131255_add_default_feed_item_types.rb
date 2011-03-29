class AddDefaultFeedItemTypes < ActiveRecord::Migration
  def self.up
    FeedItemType.create_defaults
  end

  def self.down
    # Nothing worth doing
  end
end
