class OnlyShowCertainLicensesToCp < ActiveRecord::Migration
  def self.database_model
    return "SpeciesSchemaModel"
  end
  
  def self.up
    change_table :licenses do |t|
      t.boolean :show_to_content_partners, :null => false, :default => false 
    end
    show_on_website=['public domain','cc-by-nc 3.0','cc-by 3.0','cc-by-sa 3.0','cc-by-nc-sa 3.0']
    show_on_website.each do |show_license| 
      License.find_by_title(show_license).update_attributes(:show_to_content_partners=>true)
    end
  end

  def self.down
    remove_column :licenses, :show_to_content_partners
  end

end

