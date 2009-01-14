class ContentPageArchive < ActiveRecord::Base

  belongs_to :content_page
  belongs_to :user, :foreign_key => 'last_update_user_id'

  def self.backup(page)
    
    backup_page=self.create(:content_page_id=>page.id,:last_update_user_id=>page.last_update_user_id,:page_name=>page.page_name,:title=>page.title,:language_key=>page.language_key,:content_section_id=>page.content_section_id,:sort_order=>page.sort_order,:left_content=>page.left_content,:main_content=>page.main_content,:original_creation_date=>page.created_at,:language_abbr=>page.language_abbr,:url=>page.url,:open_in_new_window=>page.open_in_new_window)
        
  end
  
  def archived_by
     
     "#{self.created_at} by #{self.user.full_name}"
     
  end
  
end
# == Schema Info
# Schema version: 20081020144900
#
# Table name: content_page_archives
#
#  id                     :integer(4)      not null, primary key
#  content_page_id        :integer(4)
#  content_section_id     :integer(4)
#  language_key           :string(255)     not null, default("")
#  left_content           :text            not null
#  main_content           :text            not null
#  original_creation_date :datetime
#  page_name              :string(255)     not null, default("")
#  sort_order             :integer(4)      not null, default(1)
#  title                  :string(255)     default("")
#  created_at             :datetime
#  updated_at             :datetime

