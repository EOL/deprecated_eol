# As shoud be clear, this is simply a collection of older versions of ContentPages.
class ContentPageArchive < ActiveRecord::Base

  belongs_to :content_page
  belongs_to :user, :foreign_key => 'last_update_user_id'

  def self.backup(page)
    self.create(:content_page_id => page.id,
                :last_update_user_id => page.last_update_user_id,
                :page_name => page.page_name,
                :title => page.title,
                :language_key => page.language_key,
                :content_section_id => page.content_section_id,
                :sort_order => page.sort_order,
                :left_content => page.left_content,
                :main_content => page.main_content,
                :original_creation_date => page.created_at,
                :created_at => page.updated_at,
                :language_abbr => page.language_abbr,
                :url => page.url,
                :open_in_new_window => page.open_in_new_window)
  end

  def archived_by
    user = self.user ? self.user.full_name : I18n.t(:unknown) 
    "#{self.created_at} by #{user}"
  end

end
