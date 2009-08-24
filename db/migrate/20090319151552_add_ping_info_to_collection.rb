class AddPingInfoToCollection < ActiveRecord::Migration
  def self.database_model
    return "SpeciesSchemaModel"
  end

  def self.up
    fishbase = Collection.fishbase
    unless fishbase.nil?
      # As of this writing, this is the ONLY collection with a ping value:
      fishbase[:ping_host_url] = 'http://www.fishbase.ca/utility/log/eol/record.php?id=%ID%'
      fishbase.save!
    end
  end

  def self.down
    remove_column :collections, :ping_host_url
  end

end
