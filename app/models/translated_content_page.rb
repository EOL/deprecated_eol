class TranslatedContentPage < ActiveRecord::Base
  belongs_to :content_page
  belongs_to :language

  validates_presence_of :title
  validates_presence_of :main_content
  validates_length_of :title, :maximum => 255

  before_destroy :archive_self

  def title_with_language
    title + " (" + self.language.iso_639_1 + ")"
  end

  def content_is_blank?
    self.main_content.blank? && self.left_content.blank?
  end

  def left_content_is_blank?
    self.left_content.blank?
  end

  def page_url
    return self.page_name.gsub(' ', '_').downcase
  end

private

  def archive_self
    TranslatedContentPageArchive.backup(self)
  end
end
