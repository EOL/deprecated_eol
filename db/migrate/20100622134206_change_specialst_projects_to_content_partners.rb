class ChangeSpecialstProjectsToContentPartners < ActiveRecord::Migration
  def self.database_model
    return "SpeciesSchemaModel"
  end
  
  def self.up
    outlinks = TocItem.find_by_label('Specialist Projects')
    outlinks.label = "Content Partners"
    outlinks.save!
  end
  
  def self.down
    outlinks = TocItem.find_by_label('Content Partners')
    outlinks.label = "Specialist Projects"
    outlinks.save!
  end
end
