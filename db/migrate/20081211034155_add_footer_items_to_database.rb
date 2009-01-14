class AddFooterItemsToDatabase < ActiveRecord::Migration
  
  def self.up
    @footer_id=ContentSection.find_by_name('Footer').id
    ContentPage.create(:page_name=>'Comments and Corrections',:title=>'Comments and Corrections',:content_section_id=>@footer_id,:sort_order=>2,:language_abbr=>'en',:url=>'/contact_us',:left_content=>'',:main_content=>'')
    ContentPage.create(:page_name=>'Encyclopedia of Life',:title=>'Encyclopedia of Life',:content_section_id=>@footer_id,:sort_order=>3,:language_abbr=>'en',:url=>'/',:left_content=>'',:main_content=>'')
  end

  def self.down
    @footer_id=ContentSection.find_by_name('Footer').id    
    ContentPage.delete_all("title='Comments and Corrections' AND content_section_id=#{@footer_id}")
    ContentPage.delete_all("title='Encyclopedia of Life' AND content_section_id=#{@footer_id}")
  end
  
end
