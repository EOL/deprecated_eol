class CreatePageStatsTable < ActiveRecord::Migration
  def self.database_model
    return "SpeciesSchemaModel"
  end
  
  def self.up
    create_table :page_stats do |t|
      t.string :active, :limit  => 1, :default => "n"
      t.string :type, :limit  => 11
      t.integer :taxa_vetted
      t.integer :taxa_unvetted
      t.integer :taxa_count
      t.integer :taxa_text
      t.integer :taxa_images
      t.integer :taxa_text_images
      t.integer :taxa_BHL_no_text
      t.integer :taxa_links_no_text
      t.integer :taxa_images_no_text
      t.integer :taxa_text_no_images
      t.integer :vet_obj_only_1cat_inCOL
      t.integer :vet_obj_only_1cat_notinCOL
      t.integer :vet_obj_morethan_1cat_inCOL
      t.integer :vet_obj_morethan_1cat_notinCOL
      t.integer :vet_obj
      t.integer :no_vet_obj
      t.integer :no_vet_obj2
      t.integer :with_BHL
      t.integer :vetted_not_published
      t.integer :vetted_unknown_published_visible_inCol
      t.integer :vetted_unknown_published_visible_notinCol
      t.integer :vetted_unknown_published_visible_uniqueGuid
      t.integer :vetted_untrusted_published_visible_uniqueGuid
      t.integer :vetted_unknown_published_notVisible_uniqueGuid
      t.integer :vetted_untrusted_published_notVisible_uniqueGuid
      t.date :date_created
      t.time :time_created
      t.string :txtfile, :limit => 255
      t.integer :total_taxa_inCol_withObject
      t.integer :total_taxa_inCol_withoutObject
      t.integer :total_taxa_notinCol_withObject
      t.integer :total_taxa_notinCol_withoutObject
      t.integer :pages_incol
      t.integer :pages_not_incol
      t.text :a_taxa_with_text
      t.timestamp :timestamp
    end
    
    execute('alter table page_stats modify a_taxa_with_text longtext default null;')
    execute('alter table page_stats modify `timestamp` timestamp default NOW();')
  end
  
  def self.down
    drop_table :page_stats
  end
end
