class ContentPartnersAddDefaults < ActiveRecord::Migration
  def up
    change_column_default(:content_partners, :notes, "")
    change_column_default(:content_partners, :description_of_data, "") 
    change_column_default(:content_partners, :description, "")
  end

  def down
    change_column_default(:content_partners, :notes, nil)
    change_column_default(:content_partners, :description_of_data, nil) 
    change_column_default(:content_partners, :description, nil)
  end
end
