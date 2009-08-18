class ChangeMedicalConceptsToBiomedicalTerms < ActiveRecord::Migration
  def self.up
    item = TocItem.find_by_label('Medical Concepts')
    if item
      item.label = 'Biomedical Terms'
      item.save 
    end
  end

  def self.down
    item = TocItem.find_by_label('Biomedical Terms')
    if item
      item.label = 'Medical Concepts'
      item.save 
    end
  end
end
