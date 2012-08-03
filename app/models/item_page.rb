class ItemPage < ActiveRecord::Base
  has_many :page_names
  belongs_to :title_item
  
  def self.sort_by_title_year(item_pages)
    item_pages.sort_by do |item|
      [item.title_item.publication_title.title,
      item.year,
      item.volume,
      item.issue,
      item.number.to_i]
    end
  end
  
  def display_string
    item_name =  ""
    item_name += year + "." unless year == '' or year == '0'
    item_name +=" Vol." + volume + "," unless volume == '' || volume == '0'
    item_name += " Issue" + issue + "," unless issue == '' || issue == '0'
    item_name
  end
  
  def publication_title
    title_item.publication_title.title
  end
  def page_url
    "http://www.biodiversitylibrary.org/page/" + id.to_s
  end
  def publication_url
    "http://www.biodiversitylibrary.org/title/" + title_item.publication_title.id.to_s
  end
end
