class TranslatedNewsItem < ActiveRecord::Base
  belongs_to :news_item
  belongs_to :language

  validates_presence_of :title
  validates_presence_of :body

  validates_length_of :title, :maximum => 255

#  before_destroy :archive_self

  def can_be_read_by?(user_wanting_access)
    user_wanting_access.is_admin? || active_translation?
  end
  def can_be_created_by?(user_wanting_access)
    user_wanting_access.is_admin?
  end
  def can_be_updated_by?(user_wanting_access)
    user_wanting_access.is_admin?
  end
  def can_be_deleted_by?(user_wanting_access)
    user_wanting_access.is_admin?
  end

  def title_with_language
    title + " (" + self.language.iso_639_1 + ")"
  end

  def content_is_blank?
    self.body.blank?
  end

  def page_url
    return self.page_name.gsub(' ', '_').downcase
  end

private

  # def archive_self
  #   TranslatedNewsItemArchive.backup(self)
  # end

end
