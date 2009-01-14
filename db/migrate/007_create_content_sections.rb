class CreateContentSections < ActiveRecord::Migration
  def self.up
    create_table :content_sections do |t|
      t.string :name, :default=>'', :null=>false
      t.string :language_key, :default=>'', :null=>false
      t.timestamps
    end

    ContentSection.create!(:name=>'About EOL')
    ContentSection.create!(:name=>'Using the Site')
    ContentSection.create!(:name=>'Press Room')
    ContentSection.create!(:name=>'Footer')  
    ContentSection.create!(:name=>'Home Page')
    ContentSection.create!(:name=>'Other')
    
  end

  def self.down
    drop_table :content_sections
  end
end
