class NewsItem < ActiveRecord::Base

  uses_translations

  # before_destroy :archive_self
  before_destroy :destroy_translations # TODO: can we have :dependent => :destroy on translations rather than this custom callback?

  validates_presence_of :page_name
  validates_length_of :page_name, :maximum => 255
  validates_uniqueness_of :page_name, :scope => :id

  def can_be_read_by?(user_wanting_access)
    user_wanting_access.is_admin? || active?
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

  def visible?
    self.activated_on <= Time.now && self.active
  end

  def not_available_in_languages(force_exist_language)
    if self.id
      languages = []
      languages << force_exist_language if force_exist_language
      languages += Language.find_by_sql("SELECT l.* FROM languages l
          LEFT JOIN translated_news_items tni ON (l.id=tni.language_id AND tni.news_item_id=#{self.id})
          WHERE tni.id IS NULL AND l.activated_on <= '#{Time.now.to_s(:db)}' order by sort_order ASC")
    else
      return Language.find_active
    end
  end

  def page_url
    all_pages_with_this_name = NewsItem.find_all_by_page_name(page_name)
    if all_pages_with_this_name.count > 1 && all_pages_with_this_name.first != self
      return self.id
    else
      return self.page_name.gsub(' ', '_').downcase
    end
  end

  def alternate_page_url
    all_pages_with_this_name = NewsItem.find_all_by_page_name(page_name)
    if all_pages_with_this_name.count == 1
      return self.id
    end
  end

private

  # def archive_self
  #   NewsItemArchive.backup(self)
  # end

  def destroy_translations
    translations.each do |translated_news_item|
      translated_news_item.destroy
    end
  end

end
