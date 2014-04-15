class ItemPage < ActiveRecord::Base
  has_many :page_names
  belongs_to :title_item
  
  def self.sort_by_title_year(item_pages)
    item_pages.sort_by do |item|
      [item.publication_title,
      item.year,
      item.volume,
      item.issue,
      item.number.to_i]
    end
  end
  
  # TODO - I18n? Vol and Issue should probably be translated.
  def display_string
    item_name = ""
    item_name += year + "." unless year == '' or year == '0'
    item_name +=" Vol. " + volume + "," unless volume == '' || volume == '0'
    item_name += " Issue " + issue + "," unless issue == '' || issue == '0'
    item_name
  end
  
  # THANK YOU for following the law of demeter! ...mostly...
  # TODO - really, whatever is stored in title_item should have #title
  # method, and we should call that here...
  def publication_title
    title_item.publication_title.title
  end
  def publication_id
    title_item.publication_title.id
  end
  def page_url
    "http://www.biodiversitylibrary.org/page/#{id}"
  end
  def publication_url
    "http://www.biodiversitylibrary.org/title/#{publication_id}"
  end
end
