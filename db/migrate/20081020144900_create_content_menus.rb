class CreateContentMenus < ActiveRecord::Migration
  def self.up
    add_column :content_pages, :url, :string, :default=>''
    add_column :content_pages, :open_in_new_window, :boolean, :default=>false
    
    feedback_menu=ContentSection.create(:name=>'Feedback')
    press_menu=ContentSection.find_by_name('Press Room')
    about_menu=ContentSection.find_by_name('About EOL')
    
    contact_us=ContentPage.create(:left_content=>'',:main_content=>'',:page_name=>'Contact Us',:title=>'Contact Us',:content_section_id=>feedback_menu.id,:sort_order=>1,:url=>'/contact_us')
    forum=ContentPage.create(:left_content=>'',:main_content=>'',:page_name=>'Forum',:title=>'Forum',:content_section_id=>feedback_menu.id,:sort_order=>2,:url=>'http://forum.eol.org',:open_in_new_window=>true)
    blog=ContentPage.create(:left_content=>'',:main_content=>'',:page_name=>'Blog',:title=>'Blog',:content_section_id=>feedback_menu.id,:sort_order=>3,:url=>'http://blog.eol.org',:open_in_new_window=>true)
    
    media_contact=ContentPage.create(:left_content=>'',:main_content=>'',:page_name=>'Media Contact',:title=>'Media Contact',:content_section_id=>press_menu.id,:sort_order=>1,:url=>'/media_contact')

    partners=ContentPage.create(:left_content=>'',:main_content=>'',:page_name=>'Content Partners',:title=>'Content Partners',:content_section_id=>about_menu.id,:sort_order=>20,:url=>'/content/partners')
    exemplars=ContentPage.create(:left_content=>'',:main_content=>'',:page_name=>'Exemplars',:title=>'Exemplars',:content_section_id=>about_menu.id,:sort_order=>25,:url=>'/content/exemplars')

  end

  def self.down
    remove_column :content_pages, :url
    remove_column :content_pages,:open_in_new_window    
    ContentSection.delete_all(['name=?','Feedback'])
    ContentPage.delete_all(['title=?','Contact Us'])
    ContentPage.delete_all(['title=?','Forum'])
    ContentPage.delete_all(['title=?','Blog'])
    ContentPage.delete_all(['title=?','Media Contact'])
    ContentPage.delete_all(['title=?','Content Partners'])
    ContentPage.delete_all(['title=?','Exemplars'])
  end
end
