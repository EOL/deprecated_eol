class CreateContentPageArchives < ActiveRecord::Migration
  def self.up
    create_table :content_page_archives do |t|
      t.integer :content_page_id
      t.string :page_name, :default=>'', :null=>false
      t.string :title, :default=>''
      t.string :language_key, :default=>'', :null=>false
      t.integer :content_section_id
      t.integer :sort_order, :default=>1, :null=>false
      t.text :left_content, :null=>false #, :default=>'' 
      t.text :main_content, :null=>false #, :default=>'' 
      t.datetime :original_creation_date
      t.timestamps
    end
  end

  def self.down
    drop_table :content_page_archives
  end
end
