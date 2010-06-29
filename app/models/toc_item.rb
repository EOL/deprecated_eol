class TocItem < SpeciesSchemaModel
  
  set_table_name 'table_of_contents'
  acts_as_tree :order => 'view_order'
  
  attr_writer :has_content
  
  has_many :info_items, :foreign_key => :toc_id
  
  has_and_belongs_to_many :data_objects, :join_table => 'data_objects_table_of_contents', :foreign_key => 'toc_id'

  def self.bhl
    cached_find(:label, 'Biodiversity Heritage Library')
  end
  
  def self.content_partners
    cached_find(:label, 'Content Partners')
  end
  
  def self.name_and_taxonomy
    cached('names_and_taxonomy') do
      TocItem.find_or_create_by_label('Names and Taxonomy')
    end
  end
  
  def self.related_names
    cached_find(:label, 'Related Names', self.name_and_taxonomy.id)
  end
  
  def self.synonyms
    cached('synonyms') do
      TocItem.find_by_label_and_parent_id('Synonyms', self.name_and_taxonomy.id)
    end
  end
  
  def self.common_names
    cached('common_names') do
      TocItem.find_by_label_and_parent_id('Common Names', self.name_and_taxonomy.id)
    end
  end
  
  def self.overview
    cached_find(:label, 'Overview')
  end
  
  def self.education
    cached_find(:label, 'Education')
  end
  
  def self.search_the_web
    cached_find(:label, 'Search the Web')
  end
  
  def self.biomedical_terms
    cached_find(:label, 'Biomedical Terms')
  end
  
  def self.literature_references
    cached_find(:label, 'Literature References')
  end
  
  def self.nucleotide_sequences
    cached_find(:label, 'Nucleotide Sequences')
  end
  
  def self.wikipedia
    cached_find(:label, 'Wikipedia')
  end
  
  def is_child?
    !(self.parent_id.nil? or self.parent_id == 0) 
  end

  def allow_user_text?
    self.info_items.length > 0 && !["Wikipedia", "Barcode"].include?(self.label)
  end
  
  def self.selectable_toc
    TocItem.find_by_sql("SELECT toc.* FROM table_of_contents toc JOIN info_items ii ON (toc.id=ii.toc_id) WHERE toc.label NOT IN ('Wikipedia', 'Barcode') ORDER BY toc.label").uniq.collect {|c| [c.label, c.id] }
  end

  def wikipedia?
    self.label == "Wikipedia" 
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

