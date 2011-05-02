class ChangeMedicalConceptsToBiomedicalTerms < ActiveRecord::Migration
  def self.up
    EOL::DB::toggle_eol_data_connections(:eol_data)
    item = TocItem.find_by_label('Medical Concepts')
    if item
      item.label = 'Biomedical Terms'
      item.save 
    end
    EOL::DB::toggle_eol_data_connections(:eol)
  end

  def self.down
    EOL::DB::toggle_eol_data_connections(:eol_data)
    item = TocItem.find_by_label('Biomedical Terms')
    if item
      item.label = 'Medical Concepts'
      item.save 
    end
    EOL::DB::toggle_eol_data_connections(:eol)
  end
end
