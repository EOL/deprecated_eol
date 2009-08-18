class TocItem < SpeciesSchemaModel
  
  set_table_name 'table_of_contents'
  acts_as_tree :order => 'view_order'
  
  attr_writer :has_content
  
  has_many :info_items, :foreign_key => :toc_id
  
  has_and_belongs_to_many :data_objects, :join_table => 'data_objects_table_of_contents', :foreign_key => 'toc_id'

  def self.bhl
    Rails.cache.fetch('toc_items/bhl') do
      TocItem.find_by_label('Biodiversity Heritage Library')
    end
  end
  
  def self.specialist_projects
    Rails.cache.fetch('toc_items/specialist_projects') do
      TocItem.find_by_label('Specialist Projects')
    end
  end
  
  def self.common_names
    Rails.cache.fetch('toc_items/common_names') do
      TocItem.find_by_label('Common Names')
    end
  end
  
  def self.overview
    Rails.cache.fetch('toc_items/overview') do
      TocItem.find_by_label('Overview')
    end
  end
  
  def self.search_the_web
    Rails.cache.fetch('toc_items/search_the_web') do
      TocItem.find_by_label('Search the Web')
    end
  end
  
  def self.biomedical_terms
    Rails.cache.fetch('toc_items/biomedical_terms') do
      TocItem.find_by_label('Biomedical Terms')
    end
  end
  
  def is_child?
    !(self.parent_id.nil? or self.parent_id == 0) 
  end

  def allow_user_text?
    self.info_items.length > 0
  end

end

# == Schema Info
# Schema version: 20081020144900
#
# Table name: table_of_contents
#
#  id         :integer(2)      not null, primary key
#  parent_id  :integer(2)      not null
#  label      :string(255)     not null
#  view_order :integer(1)      not null

