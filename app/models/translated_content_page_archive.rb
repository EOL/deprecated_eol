# As shoud be clear, this is simply a collection of older versions of ContentPages.
class ContentPageArchive < ActiveRecord::Base

  belongs_to :translated_content_page
  belongs_to :content_page
  
  def self.backup(page)
    self.create(:translated_conmtent_page_id => page.id,
                :content_page_id => page.content_page_id,
                :title => page.title,
                :left_content => page.left_content,
                :main_content => page.main_content,
                :language_id => page.language.id,
                :meta_keywords => page.meta_keywords,
                :meta_description => page.meta_description,
                :created_at => page.updated_at)
  end

end
