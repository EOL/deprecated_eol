class ChangeSpecialstProjectsToContentPartners < EOL::DataMigration
  
  def self.up
    EOL::DB::toggle_eol_data_connections(:eol_data)
    outlinks = TocItem.find_by_label('Specialist Projects')
    unless outlinks.nil?
      outlinks.label = "Content Partners"
      outlinks.save!
    end
    EOL::DB::toggle_eol_data_connections(:eol)
  end
  
  def self.down
    EOL::DB::toggle_eol_data_connections(:eol_data)
    outlinks = TocItem.find_by_label('Content Partners')
    unless outlinks.nil?
      outlinks.label = "Specialist Projects"
      outlinks.save!
    end
    EOL::DB::toggle_eol_data_connections(:eol)
  end
end
