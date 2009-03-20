class AddPingInfoToCollection < ActiveRecord::Migration
  def self.database_model
    return "SpeciesSchemaModel"
  end

  def self.up
    add_column :collections, :ping_host_url, :string, :default => nil, :null => true,
      :comment => 'This value is an optional URL to ping when a resource from this collection is viewed.  Replaces ' +
                  'the string "%ID%" with the value of the data_object\'s collection identifier.'
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
