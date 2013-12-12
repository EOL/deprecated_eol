class TranslatedNewsItem < ActiveRecord::Base
  belongs_to :news_item
  belongs_to :language

  validates_presence_of :title
  validates_presence_of :body

  validates_length_of :title, maximum: 255

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

  def content_teaser
    unless body.nil?
      full_teaser = Sanitize.clean(body[0..300], elements: %w[b i], remove_contents: %w[table script]).strip
      return nil if full_teaser.blank?
      truncated_teaser = full_teaser.split[0..20].join(' ').balance_tags
      truncated_teaser << '...' if full_teaser.length > truncated_teaser.length
      truncated_teaser
    end
  end

end
