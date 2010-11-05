class CreateWhatsThis < ActiveRecord::Migration
  def self.up
    create_table :whats_this do |t|
      t.string :name, :limit => 32
      t.string :url, :limit => 128
      t.timestamps
    end
    url = '/content/page/new_features#chapters'
    WhatsThis.create(:name => 'related names', :url => url)
    WhatsThis.create(:name => 'common names', :url => url)
    WhatsThis.create(:name => 'synonyms', :url => url)
  end

  def self.down
    drop_table :whats_this
  end
end
