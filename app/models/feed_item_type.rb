class FeedItemType < ActiveRecord::Base

  has_many :feed_items

  # TODO - i18n

  def self.create_defaults
    FeedItemType.create(:name => I18n.t("content_update"))
    FeedItemType.create(:name => I18n.t("curator_activity"))
    FeedItemType.create(:name => I18n.t("curator_comment"))
    FeedItemType.create(:name => I18n.t("user_comment"))
  end

  def self.content_update
    cached_find(:name, I18n.t("content_update"))
  end

  def self.curator_activity
    cached_find(:name, I18n.t("curator_activity"))
  end

  def self.curator_comment
    cached_find(:name, I18n.t("curator_comment"))
  end

  def self.user_comment
    cached_find(:name, I18n.t("user_comment"))
  end

end
