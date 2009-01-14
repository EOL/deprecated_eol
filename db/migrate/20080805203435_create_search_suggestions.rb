class CreateSearchSuggestions < ActiveRecord::Migration
  def self.up
    create_table :search_suggestions do |t|
      t.string :term, :default=>'', :null=>false
      t.string :scientific_name, :default=>'', :null=>false  
      t.string :common_name, :default=>'', :null=>false  
      t.string :language_label, :default=>'en', :null=>false
      t.string :image_url, :default=>'', :null=>false  
      t.string :taxon_id, :default=>'', :null=>false  
      t.text :notes, :default=>''
      t.string :content_notes, :default=>'', :null=>false
      t.integer :sort_order, :default=>1, :null=>false
      t.boolean :active, :default=>true, :null=>false
      t.timestamps
    end
  end

  def self.down
    drop_table :search_suggestions
  end
end
