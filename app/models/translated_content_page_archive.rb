# As shoud be clear, this is simply a collection of older versions of ContentPages.
class TranslatedContentPageArchive < ActiveRecord::Base

  belongs_to :translated_content_page
  belongs_to :content_page
  
  def self.backup(translated_page)
    self.create(translated_content_page_id: translated_page.id,
                content_page_id: translated_page.content_page_id,
                title: translated_page.title,
                left_content: translated_page.left_content,
                main_content: translated_page.main_content,
                language_id: translated_page.language.id,
                meta_keywords: translated_page.meta_keywords,
                meta_description: translated_page.meta_description,
                original_creation_date: translated_page.updated_at)
  end

end
