# As shoud be clear, this is simply a collection of older versions of ContentPages.
class ContentPageArchive < ActiveRecord::Base

  belongs_to :content_page
  belongs_to :user, :foreign_key => 'last_update_user_id'

  def self.backup(page)
    self.create(:content_page_id => page.id,
                :last_update_user_id => page.last_update_user_id,
                :page_name => page.page_name,
                :sort_order => page.sort_order,
                :original_creation_date => page.created_at,
                :parent_content_page_id => page.parent_content_page_id)
  end

  def archived_by
    user = self.user ? self.user.full_name : I18n.t(:unknown) 
    "#{self.created_at} by #{user}"
  end

end
